#!/usr/bin/env bash
# Points the "official" catalog at $CATALOG_REF and syncs it.
set -euo pipefail

: "${CATALOG_REF:?CATALOG_REF is required}"

if [ "$(nem catalog list | awk '$1 == "official" { print $3 }')" != "$CATALOG_REF" ]; then
  nem catalog remove official 2>/dev/null || true
  nem catalog add official "$CATALOG_REF"
fi
nem catalog update
