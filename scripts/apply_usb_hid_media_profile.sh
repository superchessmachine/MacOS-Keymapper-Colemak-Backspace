#!/usr/bin/env bash
set -euo pipefail

MATCHING='{"VendorID":0x5ac,"ProductID":0x24f,"LocationID":0x1120000}'
MAPPING='{
  "UserKeyMapping": [
    {"HIDKeyboardModifierMappingSrc": 0x700000039, "HIDKeyboardModifierMappingDst": 0x70000002A},
    {"HIDKeyboardModifierMappingSrc": 0x70000004B, "HIDKeyboardModifierMappingDst": 0xC000000E9},
    {"HIDKeyboardModifierMappingSrc": 0x70000004E, "HIDKeyboardModifierMappingDst": 0xC000000EA},
    {"HIDKeyboardModifierMappingSrc": 0x700000048, "HIDKeyboardModifierMappingDst": 0xC000000E2},
    {"HIDKeyboardModifierMappingSrc": 0x700000047, "HIDKeyboardModifierMappingDst": 0xC0000019E}
  ]
}'

hidutil property --matching "${MATCHING}" --set "${MAPPING}"
