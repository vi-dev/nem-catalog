#!/usr/bin/env bash
#
# Run the install-lint gate (`nem author lint pkgs/<pkg> --install`) for one or
# more packages, on Linux (inside the nem container image) and/or macOS (native
# on the host), against an unstable or pinned nem version.
#
#   scripts/test-pkg.sh <pkg>... [--nem <version>] [--os linux,macos] [--arch arm64|amd64]
#   scripts/test-pkg.sh --changed [--nem v0.7.0]
#
# Linux coverage comes from `ghcr.io/vi-dev/nem:<version>`; macOS coverage runs
# nem natively, provisioned the same way the setup-nem CI action does (install.sh
# for a pinned tag, `go install ...@main` for unstable). A GitHub token is
# optional — set GITHUB_TOKEN (or be logged in via `gh`) to lift GitHub API rate
# limits and reach private assets; without one the gate runs unauthenticated.
set -euo pipefail

readonly IMAGE_BASE="ghcr.io/vi-dev/nem"
readonly NEM_MODULE="github.com/vi-dev/nem"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly SCRIPT_DIR REPO_ROOT

# Tag every container this run starts so cleanup can find them. `docker run --rm`
# removes containers that exit normally, but an interrupted run (e.g. Ctrl-C
# during a long emulated build) can orphan one — so force-remove any survivors.
readonly RUN_LABEL="nem-test-pkg=$$"

# shellcheck disable=SC2329  # invoked indirectly via trap
cleanup() {
  [ -n "${AUTH_CONFIG:-}" ] && rm -f "${AUTH_CONFIG}"
  if command -v docker >/dev/null 2>&1; then
    docker ps -aq --filter "label=${RUN_LABEL}" 2>/dev/null | while read -r cid; do
      [ -n "${cid}" ] && docker rm -f "${cid}" >/dev/null 2>&1 || true
    done
  fi
  return 0
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

usage() {
  sed -n '3,14p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

host_arch() {
  case "$(uname -m)" in
    arm64 | aarch64) echo arm64 ;;
    x86_64 | amd64) echo amd64 ;;
    *) die "unsupported host architecture: $(uname -m)" ;;
  esac
}

host_is_macos() { [ "$(uname -s)" = "Darwin" ]; }

# Render nem's auth config; the token is read from $GITHUB_TOKEN at nem runtime.
write_auth_config() {
  cat >"$1" <<'EOF'
auth:
  github:
    token: '{{ env "GITHUB_TOKEN" }}'
EOF
}

changed_packages() {
  git -C "${REPO_ROOT}" diff --name-only origin/main...HEAD -- pkgs/ |
    awk -F/ 'NF>=2 {print $2}' | sort -u
}

# --- argument parsing -------------------------------------------------------

NEM_VERSION="unstable"
OS_LIST="linux,macos"
ARCH_LIST=""
CHANGED=false
PKGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --nem) NEM_VERSION="${2:?--nem needs a value}"; shift 2 ;;
    --nem=*) NEM_VERSION="${1#*=}"; shift ;;
    --os) OS_LIST="${2:?--os needs a value}"; shift 2 ;;
    --os=*) OS_LIST="${1#*=}"; shift ;;
    --arch) ARCH_LIST="${2:?--arch needs a value}"; shift 2 ;;
    --arch=*) ARCH_LIST="${1#*=}"; shift ;;
    --changed) CHANGED=true; shift ;;
    -h | --help) usage; exit 0 ;;
    --*) die "unknown flag: $1 (see --help)" ;;
    *) PKGS+=("$1"); shift ;;
  esac
done

[ -z "${ARCH_LIST}" ] && ARCH_LIST="$(host_arch)"

if [ "${CHANGED}" = true ]; then
  [ ${#PKGS[@]} -eq 0 ] || die "--changed cannot be combined with explicit package names"
  while IFS= read -r p; do
    [ -n "${p}" ] && [ -d "${REPO_ROOT}/pkgs/${p}" ] && PKGS+=("${p}")
  done <<<"$(changed_packages)"
  [ ${#PKGS[@]} -gt 0 ] || { echo "No changed packages under pkgs/; nothing to test."; exit 0; }
fi

[ ${#PKGS[@]} -gt 0 ] || { usage; die "no packages given"; }

for p in "${PKGS[@]}"; do
  [ -f "${REPO_ROOT}/pkgs/${p}/pkg.yaml" ] || die "no manifest at pkgs/${p}/pkg.yaml"
done

# --- auth (optional) --------------------------------------------------------
# A token lifts GitHub's API rate limits and reaches private assets, but the gate
# works unauthenticated against public releases — so it is optional. When absent,
# AUTH_CONFIG stays empty and no auth config is wired into the runners.

if [ -z "${GITHUB_TOKEN:-}" ] && command -v gh >/dev/null 2>&1; then
  GITHUB_TOKEN="$(gh auth token 2>/dev/null || true)"
fi

AUTH_CONFIG=""
if [ -n "${GITHUB_TOKEN:-}" ]; then
  export GITHUB_TOKEN
  AUTH_CONFIG="$(mktemp)"
  write_auth_config "${AUTH_CONFIG}"
else
  echo "warning: no GITHUB_TOKEN and no gh login — running unauthenticated; GitHub API rate limits may apply" >&2
fi

# --- runners ----------------------------------------------------------------

run_linux() {
  local pkg="$1" arch="$2"
  local auth=()
  [ -n "${AUTH_CONFIG}" ] && auth=(-v "${AUTH_CONFIG}:/nem/config.yaml:ro" -e GITHUB_TOKEN)
  docker run --rm --privileged \
    --label "${RUN_LABEL}" \
    --platform "linux/${arch}" \
    -v "${REPO_ROOT}:/catalog:ro" \
    ${auth[@]+"${auth[@]}"} \
    -w /catalog \
    "${IMAGE_BASE}:${NEM_VERSION}" \
    author lint "pkgs/${pkg}" --install
}

# Provision nem on the host once; echo the binary path (cached across packages).
MACOS_NEM_BIN=""
provision_macos_nem() {
  [ -z "${MACOS_NEM_BIN}" ] || { echo "${MACOS_NEM_BIN}"; return; }
  local dir
  dir="$(mktemp -d)"
  if [ "${NEM_VERSION}" = "unstable" ]; then
    command -v go >/dev/null 2>&1 || die "Go is required to build unstable nem for macOS"
    GOBIN="${dir}" go install "${NEM_MODULE}@main" >&2
  else
    NEM_VERSION="${NEM_VERSION}" NEM_INSTALL_DIR="${dir}" bash -c \
      'curl -fsSL "https://raw.githubusercontent.com/vi-dev/nem/${NEM_VERSION}/install.sh" | bash' >&2
  fi
  MACOS_NEM_BIN="${dir}/nem"
  echo "${MACOS_NEM_BIN}"
}

run_macos() {
  local pkg="$1" nem nemhome
  nem="$(provision_macos_nem)"
  nemhome="$(mktemp -d)"
  [ -n "${AUTH_CONFIG}" ] && cp "${AUTH_CONFIG}" "${nemhome}/config.yaml"
  (cd "${REPO_ROOT}" && NEM_HOME="${nemhome}" "${nem}" author lint "pkgs/${pkg}" --install)
}

# --- run matrix -------------------------------------------------------------

IFS=',' read -r -a OS_ARR <<<"${OS_LIST}"
IFS=',' read -r -a ARCH_ARR <<<"${ARCH_LIST}"

RESULTS=()
overall=0

record() {
  local status="$1" target="$2" pkg="$3"
  RESULTS+=("${status}  ${target}  ${pkg}")
  [ "${status}" = PASS ] || overall=1
}

for os in "${OS_ARR[@]}"; do
  case "${os}" in
    linux)
      command -v docker >/dev/null 2>&1 || die "docker is required for Linux targets"
      for arch in "${ARCH_ARR[@]}"; do
        for pkg in "${PKGS[@]}"; do
          echo "==> linux/${arch} · ${pkg} · nem ${NEM_VERSION}"
          if run_linux "${pkg}" "${arch}"; then
            record PASS "linux/${arch}" "${pkg}"
          else
            record FAIL "linux/${arch}" "${pkg}"
          fi
        done
      done
      ;;
    macos)
      if ! host_is_macos; then
        echo "warning: skipping macOS targets — host is $(uname -s), not Darwin" >&2
        continue
      fi
      for pkg in "${PKGS[@]}"; do
        echo "==> macos · ${pkg} · nem ${NEM_VERSION}"
        if run_macos "${pkg}"; then
          record PASS "macos" "${pkg}"
        else
          record FAIL "macos" "${pkg}"
        fi
      done
      ;;
    *) die "unknown os: ${os} (expected linux and/or macos)" ;;
  esac
done

echo
echo "Summary (nem ${NEM_VERSION}):"
printf '  %s\n' "${RESULTS[@]}"
exit "${overall}"
