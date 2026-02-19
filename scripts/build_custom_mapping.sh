#!/usr/bin/env bash

set -euo pipefail

DEFAULT_OUTPUT="${CUSTOM_OUTPUT:-configs/custom_mapping.json}"

echo "Create a lightweight hidutil config."
read -r -p "Where should the config be saved? [${DEFAULT_OUTPUT}] " OUTPUT_PATH
OUTPUT_PATH=${OUTPUT_PATH:-$DEFAULT_OUTPUT}
mkdir -p "$(dirname "${OUTPUT_PATH}")"

declare -a SOURCES=()
declare -a DESTINATIONS=()
INDEX=0

echo
echo "Enter key IDs like 0x700000039 (Caps Lock) or paste exact values from the inspector."
echo "Leave the source empty when you're finished."

while true; do
  read -r -p "Source key ID #$((INDEX + 1)): " SRC
  if [[ -z "${SRC}" ]]; then
    break
  fi
  read -r -p "Destination key ID: " DST
  if [[ -z "${DST}" ]]; then
    echo "Destination cannot be empty. Try again." >&2
    continue
  fi

  SOURCES+=("${SRC}")
  DESTINATIONS+=("${DST}")
  INDEX=$((INDEX + 1))

  echo "Current remaps:"
  for ((i = 0; i < ${#SOURCES[@]}; i++)); do
    printf "  %s -> %s\n" "${SOURCES[i]}" "${DESTINATIONS[i]}"
  done
  echo
done

if [[ "${#SOURCES[@]}" -eq 0 ]]; then
  echo "No mappings collected. Nothing to write." >&2
  exit 1
fi

{
  echo '{'
  echo '  "UserKeyMapping": ['
  for ((i = 0; i < ${#SOURCES[@]}; i++)); do
    COMMA=","
    if [[ $i -eq $((${#SOURCES[@]} - 1)) ]]; then
      COMMA=""
    fi
    cat <<EOF
    {
      "HIDKeyboardModifierMappingSrc": ${SOURCES[i]},
      "HIDKeyboardModifierMappingDst": ${DESTINATIONS[i]}
    }${COMMA}
EOF
  done
  echo '  ]'
  echo '}'
} >"${OUTPUT_PATH}"

echo "Wrote ${OUTPUT_PATH} with ${#SOURCES[@]} mapping(s)."
