#!/usr/bin/env bash
set -euo pipefail

base_ref="${1:-}"
head_ref="${2:-HEAD}"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to validate config JSON files." >&2
  exit 1
fi

list_config_files() {
  if [[ -n "$base_ref" ]]; then
    git diff --name-only --diff-filter=ACMR "$base_ref" "$head_ref" -- 'chains/**'
  else
    find chains -type f -name '*.json' | sort
  fi
}

failed=0
checked=0

while IFS= read -r file; do
  [[ "$file" == chains/*.json ]] || continue
  [[ -f "$file" ]] || continue

  checked=$((checked + 1))
  if ! jq empty "$file"; then
    echo "Invalid JSON config: $file" >&2
    failed=1
  fi
done < <(list_config_files)

if [[ "$checked" -eq 0 ]]; then
  echo "No changed chain config JSON files to check."
else
  echo "Checked $checked chain config JSON file(s)."
fi

exit "$failed"
