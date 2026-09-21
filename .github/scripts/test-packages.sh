#!/usr/bin/env bash
# Runs `nem catalog test` once against $TEST_CATALOG (a dir or an OCI ref).
# With ALL=true the whole catalog is tested; otherwise the "<pkg>" or
# "<pkg>@<version>" entries come from stdin, and an empty list is refused so
# a job can never fall into a full-catalog run by accident.
set -euo pipefail

: "${TEST_CATALOG:?TEST_CATALOG is required}"
: "${ALL:=false}"

args=(catalog test "$TEST_CATALOG")
if [ "$ALL" != "true" ]; then
  selected=0
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    args+=(--package "$entry")
    selected=$((selected + 1))
  done
  if [ "$selected" -eq 0 ]; then
    echo "::error::no packages on stdin and ALL is not true; refusing to test the whole catalog" >&2
    exit 1
  fi
fi
exec nem "${args[@]}"
