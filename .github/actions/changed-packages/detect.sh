#!/usr/bin/env bash
set -euo pipefail

diff_json=$(mktemp)
nem catalog diff . "$CATALOG_REF" --output json > "$diff_json"

entries='[.[] | select(.status != "removed" and .build == $build) | .name + "@" + .diff[]]'
{
  echo "build=$(jq -c --argjson build true "$entries" "$diff_json")"
  echo "prebuilt=$(jq -c --argjson build false "$entries" "$diff_json")"
} >> "$GITHUB_OUTPUT"
{
  echo "### Changed vs $CATALOG_REF"
  echo '```json'
  jq '.' "$diff_json"
  echo '```'
} >> "$GITHUB_STEP_SUMMARY"
