-- Append to ~/.config/hypr/bindings.lua (or personal-bindings.lua)
-- Replaces hardware PWM brightness keys with flicker-free CTM dimming
-- on the built-in display while preserving DDC brightness on external monitors.

local oled_dc_brightness = os.getenv("HOME") .. "/.local/bin/oled-dc-brightness"
o.rebind("XF86MonBrightnessUp", "Brightness up (DC)", oled_dc_brightness .. " +5%", { locked = true, repeating = true })
o.rebind("XF86MonBrightnessDown", "Brightness down (DC)", oled_dc_brightness .. " 5%-", { locked = true, repeating = true })
o.rebind("SHIFT + XF86MonBrightnessUp", "Brightness maximum (DC)", oled_dc_brightness .. " 100%", { locked = true, repeating = true })
o.rebind("SHIFT + XF86MonBrightnessDown", "Brightness minimum (DC)", oled_dc_brightness .. " 10%", { locked = true, repeating = true })
o.rebind("ALT + XF86MonBrightnessUp", "Brightness up precise (DC)", oled_dc_brightness .. " +1%", { locked = true, repeating = true })
o.rebind("ALT + XF86MonBrightnessDown", "Brightness down precise (DC)", oled_dc_brightness .. " 1%-", { locked = true, repeating = true })
