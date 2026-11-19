// State model for io.github.frankekn.oled-guard, kept Qt-free so it can be
// unit tested under Node.js (test/state.test.mjs).
// Treat all command output as untrusted.

var MAX_TEXT_LENGTH = 64
var VALID_PSR_STATES = { active: true, pending_reboot: true, missing: true, not_applicable: true }

var DEFAULT_STATE = {
  loaded: false,
  dcEnabled: true,
  healthy: true,
  needsHeal: false,
  internalActive: true,
  internalMonitor: "eDP-1",
  hwCur: 0,
  hwMax: 0,
  hwOk: true,
  gamma: 100,
  savedGamma: 100,
  dcOk: true,
  temp: 5700,
  warmthOn: true,
  cm: "edid",
  cmOk: true,
  psrState: "active"
}

function sanitizeText(value) {
  if (typeof value !== "string") return ""
  return value
    .replace(/[<>&"'`\x00-\x1f\x7f]/g, "")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, MAX_TEXT_LENGTH)
}

function sanitizeMonitorName(value) {
  if (typeof value !== "string") return "eDP-1"
  var trimmed = value.trim()
  return /^[A-Za-z0-9._-]+$/.test(trimmed) ? trimmed.slice(0, 32) : "eDP-1"
}

function clampBrightness(value, minFloor) {
  var floor = typeof minFloor === "number" ? minFloor : 10
  var n = Number(value)
  if (!isFinite(n)) return 100
  return Math.max(floor, Math.min(100, Math.round(n)))
}

function clampNonNegativeInt(value, maxVal) {
  var n = Number(value)
  if (!isFinite(n) || n < 0) return 0
  return Math.min(maxVal, Math.round(n))
}

function parseState(raw) {
  var data
  try {
    data = JSON.parse(String(raw || ""))
  } catch (e) {
    return null
  }
  if (!data || typeof data !== "object" || Array.isArray(data)) return null

  var dcEnabled = data.dcEnabled !== false
  var hwCur = clampNonNegativeInt(data.hwCur, 100000)
  var hwMax = clampNonNegativeInt(data.hwMax, 100000)
  var hwOk = data.hwOk === true && hwMax > 0 && hwCur === hwMax

  var minFloor = dcEnabled ? 10 : 1
  var savedGamma = clampBrightness(data.savedGamma, 10)
  var hasGamma = typeof data.gamma === "number" && isFinite(data.gamma)
  var gamma = hasGamma ? clampBrightness(data.gamma, minFloor) : savedGamma
  var dcOk = data.dcOk === true && hasGamma

  var temp = typeof data.temp === "number" && isFinite(data.temp)
    ? clampNonNegativeInt(data.temp, 20000)
    : 0
  var warmthOn = data.warmthOn === true || (temp > 0 && temp < 6000)

  var cmClean = sanitizeText(String(data.cm || "")) || "unknown"
  var cmOk = data.cmOk === true && cmClean === "edid"

  var psrRaw = typeof data.psrState === "string" ? data.psrState : ""
  var psrState = Object.prototype.hasOwnProperty.call(VALID_PSR_STATES, psrRaw) ? psrRaw : "unknown"

  var internalActive = data.internalActive !== false
  var internalMonitor = sanitizeMonitorName(data.internalMonitor)
  var needsHeal = internalActive && dcEnabled && (!hwOk || !dcOk)
  var healthy = !needsHeal

  return {
    loaded: true,
    dcEnabled: dcEnabled,
    healthy: healthy,
    needsHeal: needsHeal,
    internalActive: internalActive,
    internalMonitor: internalMonitor,
    hwCur: hwCur,
    hwMax: hwMax,
    hwOk: hwOk,
    gamma: gamma,
    savedGamma: savedGamma,
    dcOk: dcOk,
    temp: temp,
    warmthOn: warmthOn,
    cm: cmClean,
    cmOk: cmOk,
    psrState: psrState
  }
}

// Single Apple-style menu bar icon state:
//   - Active & healthy: open eye (normal foreground)
//   - Manually paused / clamshell: crossed-out eye (dimmed)
//   - Broken (unhealed drift): crossed-out eye (urgent color)
function barAppearance(state) {
  var s = state || DEFAULT_STATE
  if (!s.internalActive || !s.dcEnabled) {
    return { glyph: "\uf070", dimmed: true, urgent: false }
  }
  if (!s.healthy) {
    return { glyph: "\uf070", dimmed: false, urgent: true }
  }
  return { glyph: "\uf06e", dimmed: false, urgent: false }
}

if (typeof module !== "undefined") {
  module.exports = {
    MAX_TEXT_LENGTH: MAX_TEXT_LENGTH,
    DEFAULT_STATE: DEFAULT_STATE,
    sanitizeText: sanitizeText,
    sanitizeMonitorName: sanitizeMonitorName,
    clampBrightness: clampBrightness,
    parseState: parseState,
    barAppearance: barAppearance
  }
}
