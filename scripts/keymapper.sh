#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v hidutil >/dev/null 2>&1; then
  echo "hidutil is required but was not found on PATH." >&2
  exit 1
fi

confirm() {
  local prompt=$1
  read -r -p "${prompt} [y/N] " answer
  case "${answer}" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}

apply_config_file() {
  local config_path=$1
  if [[ ! -f "${config_path}" ]]; then
    echo "Config file ${config_path} not found." >&2
    return 1
  fi
  echo "Applying ${config_path}..."
  hidutil property --set "$(cat "${config_path}")"
}

run_key_inspector() {
  echo
  echo "Press keys or click mouse buttons to see IDs. Press Enter when you want to stop."
  "${SCRIPT_DIR}/show_key_ids.sh" &
  local inspector_pid=$!
  read -r _
  kill "${inspector_pid}" >/dev/null 2>&1 || true
  wait "${inspector_pid}" 2>/dev/null || true
}

echo "Ultra-lightweight macOS keymapper 🪶"
echo "Everything here is just bash + hidutil."
echo

if confirm "Apply the built-in Caps Lock → Backspace mapping now?"; then
  "${SCRIPT_DIR}/remap_caps_to_backspace.sh"
fi

if confirm "Do you want to look up key or button IDs first?"; then
  run_key_inspector
fi

CUSTOM_OUTPUT_PATH="configs/custom_mapping.json"
if confirm "Build a custom keymap config interactively?"; then
  read -r -p "Save custom mapping to which file? [${CUSTOM_OUTPUT_PATH}] " USER_PATH
  CUSTOM_OUTPUT_PATH=${USER_PATH:-$CUSTOM_OUTPUT_PATH}
  CUSTOM_OUTPUT="${CUSTOM_OUTPUT_PATH}" "${SCRIPT_DIR}/build_custom_mapping.sh" || true

  if [[ -f "${CUSTOM_OUTPUT_PATH}" ]]; then
    if confirm "Apply ${CUSTOM_OUTPUT_PATH} right away?"; then
      apply_config_file "${CUSTOM_OUTPUT_PATH}"
    fi
  else
    echo "Skipping apply because the config file was not created."
  fi
fi

if confirm "Apply any existing JSON config file (template, custom, etc.)?"; then
  read -r -p "Path to config JSON: " CONFIG_TO_APPLY
  if [[ -n "${CONFIG_TO_APPLY}" ]]; then
    apply_config_file "${CONFIG_TO_APPLY}"
  else
    echo "No config selected."
  fi
fi

echo
echo "Done. Re-run this helper any time you want to tweak mappings."
