# Caps Lock → Backspace mapper

This repo provides a tiny `hidutil` script plus a matching `launchd` agent that applies a Caps Lock -> Backspace mapping automatically each time you log in.

## Contents

- `scripts/remap_caps_to_backspace.sh` &mdash; runs the `hidutil property --set …` command.
- `launch_agents/com.keymapper.capslock-backspace.plist` &mdash; sample LaunchAgent that runs the script once at login.

## One-time test

```bash
./scripts/remap_caps_to_backspace.sh
```

If the command succeeds, Caps Lock immediately behaves like Backspace until the next reboot.

## Install as a background task

1. Copy the LaunchAgent into `~/Library/LaunchAgents` (create the folder if needed):
   ```bash
   cp launch_agents/com.keymapper.capslock-backspace.plist ~/Library/LaunchAgents/
   ```
2. The plist contains an absolute path to the script (`/Users/ysb/Coding/keymapper/scripts/...`). Update that path if you keep the repo somewhere else.
3. Load the agent so it runs once right away and on future logins:
   ```bash
   launchctl load -w ~/Library/LaunchAgents/com.keymapper.capslock-backspace.plist
   ```

`launchd` runs the script in the background at login, so the remap re-applies automatically after each reboot. The agent writes a small log to `/tmp/com.keymapper.capslock-backspace.log`, which is helpful for troubleshooting.

## Verify the mapping

You can inspect current mappings with:

```bash
hidutil property --get "UserKeyMapping"
```

You should see the `0x700000039` (Caps Lock) -> `0x70000002A` (Delete/Backspace) entry.

## Remove/unload

```bash
launchctl unload ~/Library/LaunchAgents/com.keymapper.capslock-backspace.plist
rm ~/Library/LaunchAgents/com.keymapper.capslock-backspace.plist
```

After unloading, reboot (or re-run `hidutil` with your preferred mapping) to restore the default behavior.
# MacOS-Colemak-Backspace
