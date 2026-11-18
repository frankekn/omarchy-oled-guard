-- Append to ~/.config/hypr/autostart.lua
-- Starts hyprsunset, restores flicker-free DC-like dimming at login,
-- and reconciles external monitors / clamshell mode automatically.

o.launch_on_start("hyprsunset")

local oled_dc_brightness = o.shell_quote(os.getenv("HOME") .. "/.local/bin/oled-dc-brightness")
hl.on("hyprland.start", function()
  hl.exec_cmd(oled_dc_brightness .. " restore")
end)
for _, event in ipairs({ "monitor.added", "monitor.removed" }) do
  hl.on(event, function()
    hl.exec_cmd(oled_dc_brightness .. " reconcile")
  end)
end
