#!/usr/bin/env bash

set -euo pipefail

if ! command -v hidutil >/dev/null 2>&1; then
  echo "hidutil is required but was not found on PATH." >&2
  exit 1
fi

MATCHING_ARGS=()
MODE_ARGS=()
SHOW_MOUSE=true
SHOW_KEYBOARD=true

usage() {
  cat <<'EOF'
Usage: show_key_ids.sh [--matching '<json or preset>'] [--keyboard-only|--mouse-only]

Examples:
  ./scripts/show_key_ids.sh
  ./scripts/show_key_ids.sh --matching '{"VendorID":0x5ac,"ProductID":0x24f}'
  ./scripts/show_key_ids.sh --matching keyboard --keyboard-only
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --matching)
      if [[ $# -lt 2 ]]; then
        echo "--matching requires an argument." >&2
        usage
        exit 1
      fi
      MATCHING_ARGS+=(--matching "$2")
      shift 2
      ;;
    --keyboard-only)
      SHOW_MOUSE=false
      shift
      ;;
    --mouse-only)
      SHOW_KEYBOARD=false
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ "${SHOW_MOUSE}" == true && "${SHOW_KEYBOARD}" == true ]]; then
  MODE_ARGS=(--keyboard --mouse)
elif [[ "${SHOW_KEYBOARD}" == true ]]; then
  MODE_ARGS=(--keyboard)
elif [[ "${SHOW_MOUSE}" == true ]]; then
  MODE_ARGS=(--mouse)
else
  echo "Nothing to monitor: either keyboard or mouse must be enabled." >&2
  exit 1
fi

TARGET_DESC="any connected device"
if [[ ${#MATCHING_ARGS[@]} -gt 0 ]]; then
  TARGET_DESC="devices matching ${MATCHING_ARGS[1]}"
fi

echo "Press any key (or click mouse buttons) on ${TARGET_DESC} to see usage IDs. Press Ctrl+C when you're done."
echo

hidutil eventmonitor "${MATCHING_ARGS[@]}" "${MODE_ARGS[@]}" |
  while IFS= read -r line; do
    if [[ "${line}" == *"Usage"* ]]; then
      printf '%s\n' "${line}"
    elif [[ "${line}" == Keyboard* || "${line}" == Mouse* ]]; then
      printf '%s\n' "${line}"
    fi
  done
