#!/usr/bin/env bash
# Points the "official" catalog to $CATALOG_REF.
set -euo pipefail

: "${CATALOG_REF:?CATALOG_REF is required}"

official_dir="${NEM_HOME:-$HOME/.nem}/catalogs/official"
current=$(nem catalog list | awk '$1 == "official" { print $3 }')

if [ "$current" != "$CATALOG_REF" ]; then
  salvage=""
  if [ -d "$official_dir" ]; then
    salvage="$(dirname "$official_dir")/.official.salvage.$$"
    mv "$official_dir" "$salvage"
  fi
  nem catalog remove official 2>/dev/null || true
  nem catalog add official "$CATALOG_REF"
  if [ -n "$salvage" ]; then
    mv "$salvage" "$official_dir"
  fi
fi

case "$CATALOG_REF" in
  /*|./*|../*|.) ;;
  *) nem catalog update ;;
esac
