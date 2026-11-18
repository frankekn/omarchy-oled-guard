-- Example rule for ~/.config/hypr/monitors.lua
-- Most laptop OLED panels cover Display P3 or wider. Leaving cm = "srgb" sends
-- unclamped sRGB values straight to wide-gamut primaries, making reds and greens
-- neon and harsh on the eyes. Setting cm = "edid" maps sRGB content cleanly to
-- the panel's EDID color primaries (similar to macOS color management).

hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.5, cm = "edid" })
