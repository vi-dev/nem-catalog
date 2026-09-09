#!/usr/bin/env bash
# Installs the packages read from stdin ("<pkg>" or "<pkg>@<version>").
#
# Packages are installed in batches, override the size with NEM_INSTALL_BATCH.
# Packages not matching host platform install nothing and still succeed.
# Failures are collected so one bad manifest does not terminate a batch.
set -uo pipefail

: "${NEM_HOME:=$HOME/.nem}"
: "${NEM_INSTALL_BATCH:=8}"

# Where pkgs/ is read from: the repo checkout by default, or a mounted
# out-of-tree catalog when the caller sets it explicitly.
: "${CATALOG_DIR:=.}"

failed=()
tested=0
entries_seen=0

reset_state() {
  nem clean --all --yes
  rm -f "$NEM_HOME/nem.toml" "$NEM_HOME/nem.lock"
}

test_packages() {
  local entry name manifest args
  for entry in "$@"; do
    name="${entry%@*}"
    manifest="$CATALOG_DIR/pkgs/$name/pkg.yaml"
    if [ ! -f "$manifest" ]; then
      echo "::warning::no manifest at $manifest; ran no tests for $entry"
      continue
    fi
    args=("$manifest")
    [ "$entry" = "$name" ] || args+=(--version "${entry#*@}")
    tested=$((tested + 1))
    nem catalog test "${args[@]}" || failed+=("$entry (test)")
  done
}

flush() {
  [ "${#batch[@]}" -gt 0 ] || return 0
  echo "::group::${batch[*]}"
  reset_state
  if nem use -g "${batch[@]}"; then
    nem status -g
    test_packages "${batch[@]}"
  else
    # nem cancels a batch's remaining installs once one fails, so the batch
    # alone cannot say which packages were actually broken. Retry them individually.
    echo "batch failed; retrying its packages individually"
    for entry in "${batch[@]}"; do
      reset_state
      if nem use -g "$entry"; then
        test_packages "$entry"
      else
        failed+=("$entry")
      fi
    done
  fi
  echo "::endgroup::"
  batch=()
}

batch=()
while IFS= read -r entry; do
  [ -n "$entry" ] || continue
  entries_seen=$((entries_seen + 1))
  batch+=("$entry")
  [ "${#batch[@]}" -lt "$NEM_INSTALL_BATCH" ] || flush
done
flush

if [ "$entries_seen" -gt 0 ] && [ "$tested" -eq 0 ]; then
  echo "::error::processed $entries_seen packages but ran zero test steps (CATALOG_DIR=$CATALOG_DIR); every manifest lookup missed" >&2
  exit 1
fi

if [ "${#failed[@]}" -gt 0 ]; then
  printf 'Failed to install: %s\n' "${failed[@]}" >&2
  exit 1
fi
