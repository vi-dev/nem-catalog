#!/usr/bin/env bash
set -euo pipefail

: "${SOURCE:?SOURCE is required}"
: "${PACKAGES:?PACKAGES is required}"

mkdir -p pr-catalog/pkgs
for pv in ${PACKAGES//,/ }; do
  p=${pv%%@*}
  if [ -d "$SOURCE/pkgs/$p" ] && [ ! -d "pr-catalog/pkgs/$p" ]; then
    cp -R "$SOURCE/pkgs/$p" "pr-catalog/pkgs/$p"
  fi
done
