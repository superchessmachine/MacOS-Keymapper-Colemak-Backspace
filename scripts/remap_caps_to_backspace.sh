#!/usr/bin/env bash

set -euo pipefail

if ! command -v hidutil >/dev/null 2>&1; then
  echo "hidutil is required but was not found on PATH." >&2
  exit 1
fi

MAPPING='{
  "UserKeyMapping": [
    {
      "HIDKeyboardModifierMappingSrc": 0x700000039,
      "HIDKeyboardModifierMappingDst": 0x70000002A
    }
  ]
}'

echo "Remapping Caps Lock to Backspace..."
hidutil property --set "${MAPPING}"
