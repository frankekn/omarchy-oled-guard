# AI 診斷與護眼設定提示詞（繁體中文）

將以下整段提示詞複製貼給你的 AI 代理（Claude Code、Antigravity、Codex、Cursor 或 OpenCode）：

---

```text
我覺得這台 Linux / Omarchy 筆電的螢幕看久了很刺眼、容易眼睛痠澀。請以這個 `omarchy-oled-guard` repository 作為參考範本，幫我一步一步完成硬體診斷與護眼設定：

### 第一步：硬體與面板實測診斷（先唯讀檢查，不要盲目套用）
1. 執行此 repo 內的 `./bin/diagnose-display`（或檢查 `/sys/devices/virtual/dmi/id/*`、`lspci -nnk`、`/sys/class/backlight/*`、並用 `edid-decode` 解碼 `/sys/class/drm/*/edid`）。
2. 找出我內建螢幕的：
   - 面板製造商與精確型號（例如 Samsung `ATNA40KW02-0` / `SDC4213`、BOE、AUO、LG 等）
   - 面板材質與更新率（OLED、Mini-LED 或 IPS LCD；60Hz / 120Hz 等）
   - 原生色域座標（是否涵蓋 Display P3 / AdobeRGB 廣色域）與色深（8-bit FRC 抖色或原生 10-bit）
   - 目前硬體背光亮度百分比、Hyprland `colorManagementPreset`、以及 GPU 驅動（Intel `xe`、`i915`、AMD `amdgpu` 或 NVIDIA）
3. 上網查詢這塊面板型號（如 Notebookcheck / Panelook 實測資料）的調光方式與 PWM 閃爍頻率（例如是否為 240Hz / 480Hz 低頻 PWM，還是高頻 PWM / 真 DC 調光）。

### 第二步：向我報告診斷結果與建議方案
先用清楚好懂的語言告訴我：
1. 這塊螢幕採用什麼調光／閃爍方式？為什麼會讓我覺得刺眼？（區分：低頻 PWM 頻閃、100% 高亮度眩光、廣色域過飽和、冷白藍光峰值、GPU PSR 自刷新微閃爍）
2. 根據我的硬體，建議啟用此 repo 範本中的哪幾項調整？（注意：如果我的螢幕本身已經是真 DC 調光 IPS LCD，就不需要把硬體背光鎖在 100%，只調整色域、色溫或 PSR 即可；若是低頻 PWM OLED，則建議完整啟用類 DC 調光。）

### 第三步：使用者確認後，照此 Repo 範本逐步設定（修改前務必備份原檔）
1. 安裝 `./bin/oled-dc-brightness` 到 `~/.local/bin/oled-dc-brightness`。
2. 參照 `examples/hypr/personal-bindings.lua` 與 `examples/hypr/autostart.lua`，綁定鍵盤亮度鍵並設定登入自動還原與外接螢幕自動切換（保留外接螢幕原有的 DDC 調光，闔蓋時不壓暗外接螢幕）。
3. 若內建螢幕為廣色域且目前為 `cm = "srgb"`，參照 `examples/hypr/monitors.lua` 將內建螢幕設為 `cm = "edid"` 收斂過飽和色彩。
4. 參照 `examples/hypr/hyprsunset.conf` 設定日間柔和紙白（如 5700K）與夜間暖光（如 4800K），並重啟 `hyprsunset`。
5. 若需要關閉面板自刷新微閃爍（PSR / Panel Replay），依照我的 GPU 驅動（Intel `xe`、`i915` 或 AMD `amdgpu`）選用 `examples/limine/` 內對應的設定檔寫入 bootloader，並重建開機映像檔。
6. 將此 repo 安裝為 Omarchy 頂部狀態列外掛（`io.github.frankekn.oled-guard`），掛載到 `~/.config/omarchy/shell.json` 並重啟 `omarchy-shell`。

### 第四步：完整驗證
執行以下檢查並回報結果：
- `hyprctl reload` 與 `hyprctl configerrors`（確認零錯誤）
- `omarchy plugin validate ~/.config/omarchy/plugins/io.github.frankekn.oled-guard`
- `~/.local/bin/oled-dc-brightness check`
- `omarchy-shell oled.guard state`
```
