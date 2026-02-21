#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHOW_KEY_SCRIPT="${SCRIPT_DIR}/show_key_ids.sh"

if ! command -v hidutil >/dev/null 2>&1; then
  echo "hidutil is required but was not found on PATH." >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required for device detection but was not found on PATH." >&2
  exit 1
fi

if [[ ! -x "${SHOW_KEY_SCRIPT}" ]]; then
  echo "Expected helper ${SHOW_KEY_SCRIPT} not found or not executable." >&2
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

tolower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

DEFAULT_MEDIA_MAPPING='{
  "UserKeyMapping": [
    {
      "HIDKeyboardModifierMappingSrc": 0x700000039,
      "HIDKeyboardModifierMappingDst": 0x70000002A
    },
    {
      "HIDKeyboardModifierMappingSrc": 0x70000004B,
      "HIDKeyboardModifierMappingDst": 0xC000000E9
    },
    {
      "HIDKeyboardModifierMappingSrc": 0x70000004E,
      "HIDKeyboardModifierMappingDst": 0xC000000EA
    },
    {
      "HIDKeyboardModifierMappingSrc": 0x700000048,
      "HIDKeyboardModifierMappingDst": 0xC000000E2
    },
    {
      "HIDKeyboardModifierMappingSrc": 0x700000047,
      "HIDKeyboardModifierMappingDst": 0xC0000019E
    }
  ]
}'

DEFAULT_PROFILE=(
  "Caps Lock|0x700000039|Backspace|0x70000002A"
  "Page Up|0x70000004B|Volume Up|0xC000000E9"
  "Page Down|0x70000004E|Volume Down|0xC000000EA"
  "Pause/Break|0x700000048|Mute|0xC000000E2"
  "Scroll Lock|0x700000047|Lock Screen|0xC0000019E"
)

ACTION_NAMES=(
  "Backspace"
  "Volume Up"
  "Volume Down"
  "Mute"
  "Play/Pause"
  "Next Track"
  "Previous Track"
  "Stop"
  "Lock Screen"
)

ACTION_IDS=(
  "0x70000002A"
  "0xC000000E9"
  "0xC000000EA"
  "0xC000000E2"
  "0xC000000CD"
  "0xC000000B5"
  "0xC000000B6"
  "0xC000000B7"
  "0xC0000019E"
)

lookup_named_key_id() {
  local key
  key=$(tolower "$1")
  case "${key}" in
    pageup|pgup|page_up)
      printf '0x70000004B\n'
      return 0
      ;;
    pagedown|pgdn|page_down)
      printf '0x70000004E\n'
      return 0
      ;;
    pause|break|pause_break)
      printf '0x700000048\n'
      return 0
      ;;
    scrolllock|scroll_lock)
      printf '0x700000047\n'
      return 0
      ;;
    insert)
      printf '0x700000049\n'
      return 0
      ;;
    home)
      printf '0x70000004A\n'
      return 0
      ;;
    delete|del)
      printf '0x70000004C\n'
      return 0
      ;;
    end)
      printf '0x70000004D\n'
      return 0
      ;;
    f13)
      printf '0x700000068\n'
      return 0
      ;;
    f14)
      printf '0x700000069\n'
      return 0
      ;;
    f15)
      printf '0x70000006A\n'
      return 0
      ;;
    f16)
      printf '0x70000006B\n'
      return 0
      ;;
    f17)
      printf '0x70000006C\n'
      return 0
      ;;
    f18)
      printf '0x70000006D\n'
      return 0
      ;;
    f19)
      printf '0x70000006E\n'
      return 0
      ;;
    f20)
      printf '0x70000006F\n'
      return 0
      ;;
  esac
  return 1
}

list_actions() {
  local idx
  for idx in "${!ACTION_NAMES[@]}"; do
    printf "  %d) %s (%s)\n" \
      "$((idx + 1))" \
      "${ACTION_NAMES[idx]}" \
      "${ACTION_IDS[idx]}"
  done
}

SELECTED_SOURCE_ID=""
prompt_for_source_id() {
  local label=$1
  local default_id=$2
  while true; do
    read -r -p "Source key for '${label}' [${default_id}] (hex ID, key name, 'list', or 'skip'): " answer || true
    if [[ -z "${answer}" ]]; then
      SELECTED_SOURCE_ID="${default_id}"
      return
    fi

    local lowered
    lowered=$(tolower "${answer}")

    case "${lowered}" in
      skip|none)
        SELECTED_SOURCE_ID=""
        return
        ;;
      default)
        SELECTED_SOURCE_ID="${default_id}"
        return
        ;;
      list)
        echo "Known key shortcuts: pageup, pagedown, pause, scrolllock, insert, home, delete, end, F13-F20."
        continue
        ;;
    esac

    if [[ "${answer}" =~ ^0[xX][0-9a-fA-F]+$ ]]; then
      SELECTED_SOURCE_ID="${answer}"
      return
    fi

    if named_id=$(lookup_named_key_id "${answer}" 2>/dev/null); then
      SELECTED_SOURCE_ID="${named_id}"
      return
    fi

    echo "Enter a hex usage ID (0x70000004B), use one of the known key names, or type 'skip'."
  done
}

SELECTED_ACTION_NAME=""
SELECTED_ACTION_ID=""
select_action_for_label() {
  local label=$1
  local default_name=$2
  local default_id=$3

  while true; do
    read -r -p "Destination action for '${label}' [${default_name}] (number/name/0x..., 'list', or 'skip'): " choice || true
    if [[ -z "${choice}" ]]; then
      SELECTED_ACTION_NAME="${default_name}"
      SELECTED_ACTION_ID="${default_id}"
      return
    fi

    local lowered
    lowered=$(tolower "${choice}")

    case "${lowered}" in
      skip|none)
        SELECTED_ACTION_NAME=""
        SELECTED_ACTION_ID=""
        return
        ;;
      list)
        list_actions
        continue
        ;;
    esac

    if [[ "${choice}" =~ ^[0-9]+$ ]]; then
      local idx=$((choice - 1))
      if (( idx >= 0 && idx < ${#ACTION_NAMES[@]} )); then
        SELECTED_ACTION_NAME="${ACTION_NAMES[idx]}"
        SELECTED_ACTION_ID="${ACTION_IDS[idx]}"
        return
      fi
    fi

    local idx
    for idx in "${!ACTION_NAMES[@]}"; do
      local action_lower
      action_lower=$(tolower "${ACTION_NAMES[idx]}")
      if [[ "${action_lower}" == "${lowered}" ]]; then
        SELECTED_ACTION_NAME="${ACTION_NAMES[idx]}"
        SELECTED_ACTION_ID="${ACTION_IDS[idx]}"
        return
      fi
    done

    if [[ "${choice}" =~ ^0[xX][0-9a-fA-F]+$ ]]; then
      SELECTED_ACTION_NAME="Custom ${choice}"
      SELECTED_ACTION_ID="${choice}"
      return
    fi

    echo "Invalid selection. Use a number from the list, an action name, 'list', or a raw usage ID."
  done
}

MEDIA_MAPPING=""
SUMMARY_SOURCES=()
SUMMARY_DESTS=()
SUMMARY_DEST_NAMES=()

build_custom_media_mapping() {
  echo
  echo "Adjust each mapping. Press Enter to keep defaults or type 'skip' to remove an entry."
  echo "Available destination actions:"
  list_actions
  echo

  declare -a SOURCES=()
  declare -a DESTS=()
  declare -a DEST_NAMES=()

  local entry
  for entry in "${DEFAULT_PROFILE[@]}"; do
    IFS='|' read -r label default_src default_dest_name default_dest_id <<<"${entry}"
    prompt_for_source_id "${label}" "${default_src}"
    local src="${SELECTED_SOURCE_ID}"
    if [[ -z "${src}" ]]; then
      echo "  Skipping ${label}."
      continue
    fi

    select_action_for_label "${label}" "${default_dest_name}" "${default_dest_id}"
    local dest="${SELECTED_ACTION_ID}"
    local dest_name="${SELECTED_ACTION_NAME}"
    if [[ -z "${dest}" ]]; then
      echo "  Skipping ${label}."
      continue
    fi

    SOURCES+=("${src}")
    DESTS+=("${dest}")
    DEST_NAMES+=("${dest_name}")
    printf "  %s → %s (%s)\n" "${src}" "${dest_name}" "${dest}"
  done

  if [[ ${#SOURCES[@]} -eq 0 ]]; then
    echo "No mappings selected; aborting." >&2
    exit 1
  fi

  SUMMARY_SOURCES=("${SOURCES[@]}")
  SUMMARY_DESTS=("${DESTS[@]}")
  SUMMARY_DEST_NAMES=("${DEST_NAMES[@]}")

  MEDIA_MAPPING=$(
    {
      echo '{'
      echo '  "UserKeyMapping": ['
      local i
      for i in "${!SOURCES[@]}"; do
        local comma=","
        if (( i == ${#SOURCES[@]} - 1 )); then
          comma=""
        fi
        cat <<EOF
    {
      "HIDKeyboardModifierMappingSrc": ${SOURCES[i]},
      "HIDKeyboardModifierMappingDst": ${DESTS[i]}
    }${comma}
EOF
      done
      echo '  ]'
      echo '}'
    }
  )
}

set_default_summary() {
  SUMMARY_SOURCES=(0x700000039 0x70000004B 0x70000004E 0x700000048 0x700000047)
  SUMMARY_DESTS=(0x70000002A 0xC000000E9 0xC000000EA 0xC000000E2 0xC0000019E)
  SUMMARY_DEST_NAMES=("Backspace" "Volume Up" "Volume Down" "Mute" "Lock Screen")
}

print_summary() {
  local i
  for i in "${!SUMMARY_SOURCES[@]}"; do
    printf "  %s → %s (%s)\n" \
      "${SUMMARY_SOURCES[i]}" \
      "${SUMMARY_DEST_NAMES[i]}" \
      "${SUMMARY_DESTS[i]}"
  done
}

DEVICE_ROWS=()
while IFS= read -r row; do
  DEVICE_ROWS+=("${row}")
done < <(
  python3 - <<'PY'
import json
import subprocess
import sys

KEYBOARD_USAGES = {
    6, 7, 8, 0x80, 0x81, 0x82, 0x83, 0x84, 0x85,
    0x88, 0x8A, 0x90, 0x91, 0x92, 0x93, 0x94, 0x95
}

try:
    proc = subprocess.run(
        ["hidutil", "list", "--ndjson"],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
except (OSError, subprocess.CalledProcessError) as exc:
    sys.stderr.write("Failed to run 'hidutil list --ndjson': %s\n" % exc)
    sys.exit(1)

seen = set()
for line in proc.stdout.splitlines():
    try:
        data = json.loads(line)
    except json.JSONDecodeError:
        continue

    if data.get("type") != "device":
        continue
    if data.get("PrimaryUsagePage") != 1:
        continue

    usage = data.get("PrimaryUsage")
    name = (data.get("Product") or data.get("IOClass") or "").lower()
    if usage not in KEYBOARD_USAGES and "keyboard" not in name:
        continue

    vendor = data.get("VendorID")
    product = data.get("ProductID")
    if vendor is None or product is None:
        continue

    location = data.get("LocationID") or 0
    key = (vendor, product, location)
    if key in seen:
        continue
    seen.add(key)

    product_name = data.get("Product") or data.get("IOClass") or "Unnamed device"
    transport = data.get("Transport") or "Unknown transport"
    built_in = bool(data.get("Built-In"))

    safe_name = product_name.replace("|", "/").strip()
    safe_transport = transport.replace("|", "/").strip()

    print(f"{vendor}|{product}|{location}|{safe_transport}|{safe_name}|{1 if built_in else 0}")

PY
)

if [[ ${#DEVICE_ROWS[@]} -eq 0 ]]; then
  echo "No keyboard-like HID devices were found. Connect your device and try again." >&2
  exit 1
fi

echo "Detected keyboard-like devices:"
for i in "${!DEVICE_ROWS[@]}"; do
  IFS='|' read -r vendor product location transport name built_in <<<"${DEVICE_ROWS[i]}"
  built_label=""
  if [[ "${built_in}" == "1" ]]; then
    built_label=", built-in"
  fi
  printf "  %d) %s [%s, Vendor %s, Product %s%s]\n" \
    "$((i + 1))" \
    "${name}" \
    "${transport}" \
    "$(printf '0x%04X' "$vendor")" \
    "$(printf '0x%04X' "$product")" \
    "${built_label}"
done

echo
read -r -p "Pick a device to remap (1-${#DEVICE_ROWS[@]}): " selection
if [[ -z "${selection}" || ! "${selection}" =~ ^[0-9]+$ ]]; then
  echo "Selection must be a number." >&2
  exit 1
fi

if (( selection < 1 || selection > ${#DEVICE_ROWS[@]} )); then
  echo "Selection ${selection} is out of range." >&2
  exit 1
fi

IFS='|' read -r vendor_id product_id location_id transport name built_in <<<"${DEVICE_ROWS[selection-1]}"

MATCHING_JSON="{\"VendorID\":${vendor_id},\"ProductID\":${product_id}"
if [[ "${location_id}" != "0" ]]; then
  MATCHING_JSON+=",\"LocationID\":${location_id}"
fi
MATCHING_JSON+='}'

echo
echo "Selected: ${name} (${transport}, Vendor $(printf '0x%04X' "$vendor_id") / Product $(printf '0x%04X' "$product_id"))"
echo "Any existing UserKeyMapping on this device will be replaced."

if confirm "Inspect usage IDs from only this device before applying the remap?"; then
  echo
  "${SHOW_KEY_SCRIPT}" --matching "${MATCHING_JSON}" --keyboard-only
fi

if confirm "Change which keys/actions are remapped before applying?"; then
  build_custom_media_mapping
else
  set_default_summary
  MEDIA_MAPPING="${DEFAULT_MEDIA_MAPPING}"
fi

echo
echo "This profile will apply the following mappings:"
print_summary

if ! confirm "Apply this mapping to the selected device now?"; then
  echo "Aborted without changes."
  exit 0
fi

echo "Applying mapping via hidutil..."
hidutil property --matching "${MATCHING_JSON}" --set "${MEDIA_MAPPING}"

echo "Done. The remap stays in place until reboot (or until you apply another mapping)."
echo "To clear it manually, run:"
echo "  hidutil property --matching '${MATCHING_JSON}' --set '{\"UserKeyMapping\":[]}'"
