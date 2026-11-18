#!/bin/bash
# Install io.github.frankekn.oled-guard plugin and CLI helper for Omarchy.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ID="io.github.frankekn.oled-guard"
PLUGIN_DEST="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
BIN_DEST="$HOME/.local/bin/oled-dc-brightness"

mkdir -p "$HOME/.local/bin" "$HOME/.config/omarchy/plugins"

install -m 755 "$REPO_DIR/bin/oled-dc-brightness" "$BIN_DEST"
printf 'Installed CLI helper: %s\n' "$BIN_DEST"

if command -v omarchy-plugin-validate >/dev/null 2>&1; then
  omarchy-plugin-validate "$REPO_DIR"
fi

rm -rf "$PLUGIN_DEST"
mkdir -p "$PLUGIN_DEST/bin" "$PLUGIN_DEST/i18n" "$PLUGIN_DEST/test"
install -m 644 "$REPO_DIR/manifest.json" "$PLUGIN_DEST/manifest.json"
install -m 644 "$REPO_DIR/Panel.qml" "$PLUGIN_DEST/Panel.qml"
install -m 644 "$REPO_DIR/OledGuardState.js" "$PLUGIN_DEST/OledGuardState.js"
install -m 755 "$REPO_DIR/bin/oled-dc-brightness" "$PLUGIN_DEST/bin/oled-dc-brightness"
install -m 755 "$REPO_DIR/bin/diagnose-display" "$PLUGIN_DEST/bin/diagnose-display"
install -m 644 "$REPO_DIR/i18n/en.json" "$PLUGIN_DEST/i18n/en.json"
install -m 644 "$REPO_DIR/i18n/zh-TW.json" "$PLUGIN_DEST/i18n/zh-TW.json"
install -m 644 "$REPO_DIR/test/state.test.mjs" "$PLUGIN_DEST/test/state.test.mjs"
printf 'Installed Omarchy plugin: %s\n' "$PLUGIN_DEST"

if command -v omarchy-shell >/dev/null 2>&1; then
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
fi
if command -v omarchy-plugin-enable >/dev/null 2>&1; then
  omarchy-plugin-enable "$PLUGIN_ID" --section right >/dev/null 2>&1 || true
fi

printf '\nDone! Next steps:\n'
printf '  1. Review examples/hypr/ to bind brightness keys and autostart restore.\n'
printf '  2. Run: omarchy restart shell\n'
printf '  3. Check status anytime with: oled-dc-brightness check\n'
