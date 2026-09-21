#!/usr/bin/env bash
# Runs test-packages.sh inside the rootless nem image.
#
# Env in:
#   TEST_CATALOG  catalog to test: an OCI ref, or a dir path mounted
#                 read-only into the container
#   ALL           forwarded to test-packages.sh
#   CATALOG_REF   optional catalog configured as "official" for dependency
#                 fallback; leave unset when the test catalog is complete
#   IMAGE         image to run (default ghcr.io/vi-dev/nem:unstable-rootless)
set -euo pipefail

: "${IMAGE:=ghcr.io/vi-dev/nem:unstable-rootless}"
: "${TEST_CATALOG:?TEST_CATALOG is required}"

scripts=$(cd "$(dirname "$0")" && pwd)
checkout=$(cd "$scripts/../.." && pwd)
args=(-v "$checkout:/checkout:ro" -e ALL -e CATALOG_REF)
if [ -f "$HOME/.docker/config.json" ]; then
  args+=(-v "$HOME/.docker:/creds:ro" -e DOCKER_CONFIG=/creds)
fi
case "$TEST_CATALOG" in
  /*|./*|../*|.)
    args+=(-v "$(cd "$TEST_CATALOG" && pwd):/catalog:ro" -e TEST_CATALOG=/catalog)
    ;;
  *)
    args+=(-e TEST_CATALOG="$TEST_CATALOG")
    ;;
esac

exec docker run --rm -i "${args[@]}" \
  --entrypoint bash \
  "$IMAGE" \
  -c 'set -e
      if [ -n "${CATALOG_REF:-}" ]; then
        /checkout/.github/scripts/configure-official.sh
      fi
      /checkout/.github/scripts/test-packages.sh'
