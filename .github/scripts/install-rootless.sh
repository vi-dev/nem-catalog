#!/usr/bin/env bash
# Runs install-each.sh inside the rootless nem image.
#
# Env in:
#   CATALOG_REF   catalog configured as "official" in the container: an OCI
#                 ref, or a dir path mounted read-only into the container
#   IMAGE         image to run (default ghcr.io/vi-dev/nem:unstable-rootless)
set -euo pipefail

: "${IMAGE:=ghcr.io/vi-dev/nem:unstable-rootless}"
: "${CATALOG_REF:?CATALOG_REF is required}"

scripts=$(cd "$(dirname "$0")" && pwd)
checkout=$(cd "$scripts/../.." && pwd)
args=(-v "$checkout:/checkout:ro" -e CATALOG_DIR=/checkout)
if [ -f "$HOME/.docker/config.json" ]; then
  args+=(-v "$HOME/.docker:/creds:ro" -e DOCKER_CONFIG=/creds)
fi
case "$CATALOG_REF" in
  /*|./*|../*|.)
    args+=(-v "$(cd "$CATALOG_REF" && pwd):/catalog:ro" -e CATALOG_REF=/catalog -e CATALOG_DIR=/catalog)
    ;;
  *)
    args+=(-e CATALOG_REF="$CATALOG_REF")
    ;;
esac
if [ -d "$HOME/.nem/catalogs" ]; then
  args+=(-v "$HOME/.nem/catalogs:/catalog-seed:ro")
fi

exec docker run --rm -i "${args[@]}" \
  --entrypoint bash \
  "$IMAGE" \
  -c 'set -e
      if [ -d /catalog-seed ]; then
        dest="${NEM_HOME:-$HOME/.nem}/catalogs"
        mkdir -p "$dest"
        cp -R /catalog-seed/. "$dest/"
      fi
      /checkout/.github/scripts/configure-catalog.sh
      /checkout/.github/scripts/install-each.sh'
