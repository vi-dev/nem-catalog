#!/usr/bin/env bash
set -euo pipefail

: "${PACKAGES:=}"
: "${DRY_RUN:=false}"
if [ "$MISSING" != "true" ] && [ -z "${PACKAGES// }" ]; then
  echo "nothing selected; skipping build"
  exit 0
fi

args=(catalog build "$CATALOG")
if [ "$MISSING" = "true" ]; then args+=(--missing); fi
for pv in ${PACKAGES//,/ }; do args+=(--package "$pv"); done
if [ "$PUSH" = "true" ]; then args+=(--push); fi
if [ "$FORCE" = "true" ]; then args+=(--force); fi
if [ "$DRY_RUN" = "true" ]; then args+=(--dry-run); fi
nem "${args[@]}"
