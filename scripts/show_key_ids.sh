#!/usr/bin/env bash

set -euo pipefail

if ! command -v hidutil >/dev/null 2>&1; then
  echo "hidutil is required but was not found on PATH." >&2
  exit 1
fi

echo "Press any key (or click mouse buttons) to see their usage IDs. Press Ctrl+C when you're done."
echo

hidutil eventmonitor --keyboard --mouse |
  while IFS= read -r line; do
    if [[ "${line}" == *"Usage"* ]]; then
      printf '%s\n' "${line}"
    elif [[ "${line}" == Keyboard* || "${line}" == Mouse* ]]; then
      printf '%s\n' "${line}"
    fi
  done
