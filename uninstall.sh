#!/bin/bash
# Uninstall io.github.frankekn.oled-guard plugin and restore default 100% CTM gamma.

set -euo pipefail

PLUGIN_ID="io.github.frankekn.oled-guard"
PLUGIN_DEST="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
BIN_DEST="$HOME/.local/bin/oled-dc-brightness"

if [[ -x $BIN_DEST ]]; then
  "$BIN_DEST" --no-osd reset >/dev/null 2>&1 || true
fi

if command -v omarchy-plugin-disable >/dev/null 2>&1; then
  omarchy-plugin-disable "$PLUGIN_ID" >/dev/null 2>&1 || true
fi

rm -rf "$PLUGIN_DEST"
rm -f "$BIN_DEST"

if command -v omarchy-shell >/dev/null 2>&1; then
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
fi

printf 'Removed %s and %s.\n' "$PLUGIN_DEST" "$BIN_DEST"
printf 'Remember to remove any custom brightness bindings added to ~/.config/hypr/.\n'
