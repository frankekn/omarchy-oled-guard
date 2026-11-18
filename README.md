# omarchy-oled-guard

Flicker-free **DC-like dimming**, hardware display diagnostics, and an **Apple-style Eye Comfort** top-bar plugin (`io.github.frankekn.oled-guard`) for OLED laptops running [Omarchy](https://omarchy.org/) (Arch Linux + Hyprland).

Includes ready-to-paste **AI Agent Prompts** ([English](prompts/diagnose-and-setup.en.md) · [繁體中文](prompts/diagnose-and-setup.zh-TW.md)) so anyone experiencing eye strain on Linux can diagnose their exact laptop panel and apply the right protections step by step using this repository as a template.

---

## Why Laptop OLED Screens Cause Eye Strain ("辣眼睛")

Many thin-and-light OLED laptops (such as 14" 60Hz/120Hz Samsung AMOLED panels like `ATNA40KW02-0` / `SDC4213`) combine four triggers of visual fatigue:

1. **Low-Frequency PWM Flicker (240 Hz – 480 Hz)**: Lowering hardware brightness chops pixel emission on and off hundreds of times per second. At 50% hardware brightness, the screen sits completely black for half of every cycle.
2. **Wide-Gamut Oversaturation**: Most OLED panels exceed Display P3, yet compositors default to `cm = "srgb"`, feeding unclamped sRGB values straight into wide-gamut primaries and producing harsh neon reds and greens.
3. **Cold Blue-Light Spike**: Uncalibrated OLED white points have a sharp short-wavelength blue emission peak.
4. **Panel Self-Refresh (PSR / Panel Replay) Transitions**: GPU power-saving self-refresh on Intel (`xe` / `i915`) and AMD (`amdgpu`) can cause subtle voltage/luminance shifts between static and scrolling frames.

### How DC-Like Dimming Solves It on OLED

Unlike LCDs (which have a backlight behind liquid crystals), OLED pixels are self-emissive and driven by per-pixel current. By **locking hardware backlight at 100%** (minimizing PWM off-time to the panel's narrowest refresh dip) and scaling RGB via the GPU's **hardware Color Transformation Matrix (CTM)** through `hyprsunset`:

- **Eliminates ~85–90% of mid/low-brightness PWM modulation** by lowering pixel drive current instead of widening black PWM off-bars.
- **Zero GPU shader overhead** — runs in the display engine's hardware CTM pipe, dimming the hardware cursor and lock screen uniformly.
- **Screenshots & recordings stay 100% normal brightness** — screen capture reads pre-CTM buffers.
- **External monitor & clamshell aware** — external displays continue using hardware DDC brightness, and closing the laptop lid automatically restores 100% CTM so external monitors are never dimmed.

---

## Menu Bar Plugin Design

Designed like macOS Control Center's **Display** popover — zero cryptic acronyms on screen:

- **Single Menu Bar Eye Icon**:
  - `󰈈` **Lit Eye**: Eye Comfort is active (auto-heals in the background every 5s if hardware backlight or `hyprsunset` ever drifts).
  - `󰈉` **Dimmed Crossed-Eye**: Manually paused (right-click the icon to toggle on/off with seamless brightness handoff).
  - `󰈉` **Red Crossed-Eye**: Shown only if an underlying setting drifted and automatic self-healing failed.
- **Popover Controls** (left-click the icon, or scroll the wheel on the icon to adjust brightness):
  - **Brightness** slider (`10%` – `100%`)
  - **Flicker-Free Dimming** (`防閃爍調光`)
  - **True Tone Natural Color** (`原彩柔和顯示` — toggles `cm = "edid"` vs `"srgb"`)
  - **Night Shift Warmth** (`暖光護眼` — 5700K paper-white by day, 4800K warm light at night)

---

## Diagnose Your Own Laptop with an AI Agent (Copy-Paste Prompt)

Clone this repository, open it in **Claude Code**, **Antigravity**, **Codex**, **Cursor**, or **OpenCode**, and paste the prompt below. The agent will inspect your exact panel EDID, look up its PWM behavior, explain why your screen feels harsh, and apply only the steps your hardware actually needs.

```bash
git clone https://github.com/frankekn/omarchy-oled-guard.git
cd omarchy-oled-guard
```

### 繁體中文提示詞（完整版見 [`prompts/diagnose-and-setup.zh-TW.md`](prompts/diagnose-and-setup.zh-TW.md)）

```text
我覺得這台 Linux / Omarchy 筆電的螢幕看久了很刺眼、容易眼睛痠澀。請以當前目錄的 `omarchy-oled-guard` repo 作為範本，幫我一步一步完成硬體診斷與護眼設定：

1. 先唯讀執行 `./bin/diagnose-display`（讀取 DMI 機型、GPU 驅動、`/sys/class/backlight/*`，並用 `edid-decode` 解碼 `/sys/class/drm/*/edid`），找出面板精確型號、材質（OLED / Mini-LED / IPS）、更新率、色域座標與色深。
2. 上網查詢該面板型號的實測調光方式與 PWM 頻率（如 Notebookcheck / Panelook），先用白話向我報告「為什麼這塊螢幕會傷眼」以及建議啟用本 repo 範本中的哪幾項保護（若本身已是真 DC 調光 IPS 則不必鎖 100% 背光；若是低頻 PWM OLED 則完整啟用類 DC 調光）。
3. 等我確認後，先備份設定檔，再依照 `examples/hypr/`、`examples/limine/` 與 `./install.sh` 幫我設定好類 DC 調光亮度鍵、開機自動還原、`cm = "edid"` 原彩色域收斂、日夜護眼色溫、對應 GPU（Intel `xe` / `i915` 或 AMD `amdgpu`）的關閉 PSR 參數，以及頂部狀態列外掛 `io.github.frankekn.oled-guard`。
4. 最後執行 `hyprctl reload`、`hyprctl configerrors`、`omarchy plugin validate ~/.config/omarchy/plugins/io.github.frankekn.oled-guard` 與 `~/.local/bin/oled-dc-brightness check` 驗證並回報結果。
```

### English Prompt (Full version in [`prompts/diagnose-and-setup.en.md`](prompts/diagnose-and-setup.en.md))

```text
My eyes feel strained looking at this Linux / Omarchy laptop screen. Using this `omarchy-oled-guard` repo as the reference template, please diagnose my display hardware and set up eye-comfort protections step by step:

1. Run `./bin/diagnose-display` (read-only) to inspect DMI model, GPU driver, `/sys/class/backlight/*`, and decode `/sys/class/drm/*/edid` via `edid-decode` to find my exact panel model, display technology (OLED / Mini-LED / IPS), refresh rate, color primaries, and bit depth.
2. Look up that exact panel model's PWM dimming frequency in review databases (e.g. Notebookcheck / Panelook), then explain in plain language why my screen causes eye strain and which protections from this repo apply to my hardware.
3. Once I confirm, back up existing configs and follow `examples/hypr/`, `examples/limine/`, and `./install.sh` to configure flicker-free DC-like brightness keys, login restore, `cm = "edid"` gamut clamping, day/night warmth, GPU-appropriate PSR kernel parameters, and the `io.github.frankekn.oled-guard` top-bar plugin.
4. Validate with `hyprctl reload`, `hyprctl configerrors`, `omarchy plugin validate ~/.config/omarchy/plugins/io.github.frankekn.oled-guard`, and `~/.local/bin/oled-dc-brightness check`.
```

---

## Manual Installation & Step-by-Step Setup

### 1. Install the Plugin & CLI

Via Omarchy's plugin manager:

```bash
omarchy plugin add https://github.com/frankekn/omarchy-oled-guard.git --enable
install -Dm755 ~/.config/omarchy/plugins/io.github.frankekn.oled-guard/bin/oled-dc-brightness ~/.local/bin/oled-dc-brightness
omarchy restart shell
```

Or from a local checkout:

```bash
./install.sh
omarchy restart shell
```

### 2. Apply the Hyprland & Bootloader Templates

Review and merge the annotated templates under [`examples/`](examples/):

| Template | Target Location | Purpose |
| :--- | :--- | :--- |
| [`examples/hypr/personal-bindings.lua`](examples/hypr/personal-bindings.lua) | `~/.config/hypr/bindings.lua` | Rebinds `XF86MonBrightnessUp` / `Down` to flicker-free DC dimming on the laptop panel while keeping DDC for external monitors |
| [`examples/hypr/autostart.lua`](examples/hypr/autostart.lua) | `~/.config/hypr/autostart.lua` | Starts `hyprsunset`, restores saved brightness at login, and reconciles external monitors / clamshell mode |
| [`examples/hypr/monitors.lua`](examples/hypr/monitors.lua) | `~/.config/hypr/monitors.lua` | Sets `cm = "edid"` on the built-in OLED panel to clamp Display-P3 oversaturation |
| [`examples/hypr/hyprsunset.conf`](examples/hypr/hyprsunset.conf) | `~/.config/hypr/hyprsunset.conf` | Sets gentle 5700K daytime paper-white and 4800K evening warmth |
| [`examples/limine/intel-xe-no-psr.conf`](examples/limine/intel-xe-no-psr.conf) | `/etc/limine-entry-tool.d/` | Disables PSR & Panel Replay on Intel Lunar Lake / Panther Lake (`xe`) |
| [`examples/limine/intel-i915-no-psr.conf`](examples/limine/intel-i915-no-psr.conf) | `/etc/limine-entry-tool.d/` | Disables PSR on Intel `i915` laptops |
| [`examples/limine/amd-no-psr.conf`](examples/limine/amd-no-psr.conf) | `/etc/limine-entry-tool.d/` | Disables PSR / PSR-SU on AMD Ryzen `amdgpu` laptops |

After editing Hyprland Lua files, always validate:

```bash
hyprctl reload && hyprctl configerrors
```

If you added a Limine kernel parameter drop-in, rebuild your UKI and reboot once:

```bash
sudo limine-mkinitcpio
```

---

## Verification & CLI Usage

```bash
# Run hardware & EDID diagnostic dump
./bin/diagnose-display

# Verify all 5 eye-comfort layers at once
oled-dc-brightness check

# Adjust or toggle from terminal / scripts
oled-dc-brightness 75%
oled-dc-brightness +5%
oled-dc-brightness 5%-
oled-dc-brightness dc off     # Pause anti-flicker seamlessly
oled-dc-brightness dc on      # Resume anti-flicker seamlessly
oled-dc-brightness gamut on   # Enable cm = "edid" natural colors
oled-dc-brightness warmth on  # Enable 5700K/4800K warmth

# Validate plugin manifest & run unit tests
omarchy plugin validate .
node --test test/state.test.mjs
```

---

## License

[MIT](LICENSE) © Frank Yang
