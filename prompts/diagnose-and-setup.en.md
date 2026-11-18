# AI Diagnostic & Eye-Comfort Setup Prompt (English)

Copy and paste the prompt below into your AI coding agent (Claude Code, Antigravity, Codex, Cursor, or OpenCode):

---

```text
My eyes feel strained / harsh when looking at this Linux / Omarchy laptop screen. Using this `omarchy-oled-guard` repository as the reference template, please diagnose my display hardware and set up the appropriate eye-comfort protections step by step:

### Step 1: Read-Only Hardware & Panel Diagnosis
1. Run `./bin/diagnose-display` from this repository (or inspect `/sys/devices/virtual/dmi/id/*`, `lspci -nnk`, `/sys/class/backlight/*`, and decode `/sys/class/drm/*/edid` with `edid-decode`).
2. Identify my built-in panel's:
   - Exact manufacturer and panel part number (e.g., Samsung `ATNA40KW02-0` / `SDC4213`, BOE, AUO, LG)
   - Display technology and refresh rate (OLED, Mini-LED, or IPS LCD; 60Hz / 120Hz, etc.)
   - Native color gamut primaries (Display P3 / AdobeRGB wide gamut vs sRGB) and color depth (8-bit + FRC dithering vs native 10-bit)
   - Current hardware backlight level, Hyprland `colorManagementPreset`, and GPU kernel driver (Intel `xe`, `i915`, AMD `amdgpu`, or NVIDIA)
3. Search hardware review databases (such as Notebookcheck or Panelook) for this exact panel model's dimming method and PWM flicker frequency (e.g., 240Hz / 480Hz low-frequency PWM vs high-frequency PWM vs true DC dimming).

### Step 2: Report Findings & Tailored Plan Before Editing
Explain clearly in plain language:
1. How my panel dims brightness and the specific reasons it causes eye strain on my hardware (low-frequency PWM modulation, 100% brightness glare/halation, unclamped wide-gamut oversaturation, harsh 6500K blue spike, or GPU PSR / Panel Replay self-refresh voltage transitions).
2. Which protections from this template repository apply to my machine. (Note: if my panel is already a flicker-free true DC-dimmed IPS LCD, do NOT lock hardware backlight at 100% — only apply gamut clamping, warmth, or PSR fixes as appropriate; if it uses low-frequency PWM such as a 60Hz/120Hz OLED, recommend full DC-like dimming.)

### Step 3: Apply the Template Step by Step (Back Up Configs First)
Once I confirm:
1. Install `./bin/oled-dc-brightness` to `~/.local/bin/oled-dc-brightness`.
2. Following `examples/hypr/personal-bindings.lua` and `examples/hypr/autostart.lua`, rebind brightness keys and add login restore + external monitor / clamshell reconciliation (keeping DDC brightness working on external monitors).
3. If the built-in panel is wide-gamut and currently running `cm = "srgb"`, set `cm = "edid"` for the internal connector in `~/.config/hypr/monitors.lua` (see `examples/hypr/monitors.lua`).
4. Configure gentle daytime warmth (e.g. 5700K) and evening warmth (e.g. 4800K) in `~/.config/hypr/hyprsunset.conf` (see `examples/hypr/hyprsunset.conf`) and restart `hyprsunset`.
5. If disabling Panel Self-Refresh (PSR / Panel Replay) is appropriate for my GPU driver (`xe`, `i915`, or `amdgpu`), apply the matching kernel parameter template from `examples/limine/` and rebuild the boot image.
6. Install this repository as the Omarchy topbar plugin (`io.github.frankekn.oled-guard`), enable it in `~/.config/omarchy/shell.json`, and run `omarchy restart shell`.

### Step 4: Verify Everything
Run and report:
- `hyprctl reload` and `hyprctl configerrors` (must be zero errors)
- `omarchy plugin validate ~/.config/omarchy/plugins/io.github.frankekn.oled-guard`
- `~/.local/bin/oled-dc-brightness check`
- `omarchy-shell oled.guard state`
```
