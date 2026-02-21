# Lightweight macOS keymapper

Still all about that Colemak-friendly Caps Lock → Backspace remap, but now with a couple of ultra-lightweight helpers for any macOS keymap you want to throw at `hidutil`.

## What's inside

- `scripts/remap_caps_to_backspace.sh` — single-purpose Bash script that keeps the original behavior alive.
- `launch_agents/com.keymapper.capslock-backspace.plist` — optional LaunchAgent that reruns the script each time you log in.
- `scripts/show_key_ids.sh` — runs `hidutil eventmonitor` so you can press keys or mouse buttons and read their usage IDs instantly (with optional matching filters).
- `scripts/build_custom_mapping.sh` — tiny interactive script that asks “map what to what?” and writes a JSON config (showing your growing list of remaps as you add them).
- `scripts/device_media_mapper.sh` — enumerates connected keyboards, lets you customize the Page Up/Down/Pause/Scroll Lock profile, then applies it to whichever device you pick.
- `configs/keymap.template.json` — ready-to-edit template if you’d rather type mappings manually.
- `scripts/keymapper.sh` — an all-in-one helper that walks through the backspace remap, key-ID tester, and custom mapping workflow in one terminal session.

All of this stays super minimal: only Bash, stock `python3`, and the built-in `hidutil`, no installers, and the only files produced are the plain JSON configs you ask for.

## Quick one-off test (Caps → Backspace)

```bash
./scripts/remap_caps_to_backspace.sh
```

As soon as it succeeds, Caps Lock behaves like Backspace until you reboot or apply another map.

## Keep it running every login

1. Copy the LaunchAgent into `~/Library/LaunchAgents` (create it first if missing):
   ```bash
   cp launch_agents/com.keymapper.capslock-backspace.plist ~/Library/LaunchAgents/
   ```
2. Edit the plist and point the `ProgramArguments` entry at your local repo path (the sample uses `/Users/ysb/Coding/keymapper/...`).
3. Load it so it fires once now and automatically on future logins:
   ```bash
   launchctl load -w ~/Library/LaunchAgents/com.keymapper.capslock-backspace.plist
   ```

`launchd` writes a small log to `/tmp/com.keymapper.capslock-backspace.log`, which is handy if you need to troubleshoot.

## Inspect key/button IDs

```bash
./scripts/show_key_ids.sh
./scripts/show_key_ids.sh --matching '{"VendorID":0x5ac,"ProductID":0x24f}' --keyboard-only
```

It streams `UsagePage`/`Usage` IDs for each keypress or mouse click. Press `Ctrl+C` (or let the all-in-one helper stop it for you) when you’re done collecting numbers. Pass `--matching '<json or preset>'` to limit output to a specific device (e.g., one keyboard) before you build a per-device config.

## Remap special keys on one keyboard

```bash
./scripts/device_media_mapper.sh
```

The helper uses `hidutil list --ndjson` (parsed by the system `python3`) to show every connected keyboard-like device. Pick your external keyboard, optionally run the inspector scoped to that device, then either keep the default profile below or customize each entry right in the script (type `list` when prompted to see all destination actions, or `skip` to remove an entry):

| Default source | Default destination |
| -------------- | ------------------- |
| Caps Lock      | Backspace           |
| Page Up        | Volume Up           |
| Page Down      | Volume Down         |
| Pause / Break  | Mute                |
| Scroll Lock    | Lock Screen         |

The `Lock Screen` destination uses the HID consumer “Terminal Lock / Screensaver” usage. If you ever want to clear the profile for that device, run `hidutil property --matching '<same JSON>' --set '{"UserKeyMapping":[]}'`.

## Build a config interactively

```bash
./scripts/build_custom_mapping.sh
```

Pick an output path (defaults to `configs/custom_mapping.json`), then keep answering “source key → destination key” pairs. After each entry you’ll see the full list so you can double-check before writing the JSON file.

## Prefer editing by hand?

`configs/keymap.template.json` is a valid `hidutil` file with two sample remaps. Duplicate it, change the usage IDs, and feed the result straight into `hidutil`:

```bash
hidutil property --set "$(cat path/to/your_config.json)"
```

## All-in-one lightweight workflow

```bash
./scripts/keymapper.sh
```

The helper asks if you want to:

1. Apply the original Caps Lock → Backspace remap.
2. Peek at raw key IDs (it runs the inspector in the background and stops it when you press Enter).
3. Target a specific keyboard and map (or customize) Page Up/Down/Pause/Scroll Lock to volume/mute/lock actions.
4. Build a custom keymap file (using the same “show your list on every addition” flow as `build_custom_mapping.sh`) and optionally apply it immediately.
5. Apply any existing JSON file (template, downloaded, etc.).

Re-run it whenever you want to toggle the simple remap, generate a fresh config, or just sanity-check a key ID.

## Verify active mappings

```bash
hidutil property --get "UserKeyMapping"
```

You should see entries such as `0x700000039` → `0x70000002A` for the Caps → Backspace swap.

## Remove/unload the LaunchAgent

```bash
launchctl unload ~/Library/LaunchAgents/com.keymapper.capslock-backspace.plist
rm ~/Library/LaunchAgents/com.keymapper.capslock-backspace.plist
```

After unloading, reboot (or apply a different JSON config) to restore the default layout.
