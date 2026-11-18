import test from "node:test"
import assert from "node:assert/strict"
import { createRequire } from "node:module"

const require = createRequire(import.meta.url)
const { sanitizeText, sanitizeMonitorName, clampBrightness, parseState, barAppearance } = require("../OledGuardState.js")

test("shows calm eye icon when protection is active and healthy", () => {
  const s = parseState(JSON.stringify({
    dcEnabled: true,
    internalMonitor: "eDP-1",
    hwCur: 300,
    hwMax: 300,
    hwOk: true,
    gamma: 75,
    savedGamma: 75,
    dcOk: true,
    temp: 5700,
    warmthOn: true,
    cm: "edid",
    cmOk: true,
    psrState: "pending_reboot",
    internalActive: true
  }))
  assert.equal(s.healthy, true)
  assert.equal(s.needsHeal, false)
  assert.equal(s.internalMonitor, "eDP-1")
  assert.deepEqual(barAppearance(s), {
    glyph: "\u{f0208}",
    dimmed: false,
    urgent: false
  })
})

test("shows dimmed crossed-eye when user turns protection off", () => {
  const s = parseState(JSON.stringify({
    dcEnabled: false,
    internalMonitor: "eDP-2",
    hwCur: 210,
    hwMax: 300,
    hwOk: false,
    gamma: 70,
    savedGamma: 70,
    dcOk: true,
    temp: 6500,
    warmthOn: false,
    cm: "srgb",
    cmOk: false,
    psrState: "active",
    internalActive: true
  }))
  assert.equal(s.dcEnabled, false)
  assert.equal(s.healthy, true)
  assert.equal(s.internalMonitor, "eDP-2")
  assert.deepEqual(barAppearance(s), {
    glyph: "\u{f0209}",
    dimmed: true,
    urgent: false
  })
})

test("flags needsHeal and urgent crossed-eye when hardware backlight drifts", () => {
  const s = parseState(JSON.stringify({
    dcEnabled: true,
    hwCur: 150,
    hwMax: 300,
    hwOk: false,
    gamma: 75,
    savedGamma: 75,
    dcOk: true,
    temp: 5700,
    warmthOn: true,
    cm: "edid",
    cmOk: true,
    psrState: "active",
    internalActive: true
  }))
  assert.equal(s.healthy, false)
  assert.equal(s.needsHeal, true)
  assert.deepEqual(barAppearance(s), {
    glyph: "\u{f0209}",
    dimmed: false,
    urgent: true
  })
})

test("neutralizes markup-shaped input and bounds untrusted fields", () => {
  const malicious = '<img src="https://example.invalid/tracker"><b>srgb</b>'
  assert.equal(sanitizeText(malicious).includes("<"), false)
  assert.equal(sanitizeText(malicious).includes(">"), false)
  assert.equal(sanitizeMonitorName("eDP-1; rm -rf /"), "eDP-1")

  const s = parseState(JSON.stringify({
    dcEnabled: true,
    internalMonitor: "eDP-1$(id)",
    hwCur: 9999999,
    hwMax: 300,
    hwOk: true,
    gamma: -50,
    savedGamma: 500,
    dcOk: true,
    temp: 999999,
    warmthOn: false,
    cm: malicious,
    cmOk: true,
    psrState: "<script>alert(1)</script>",
    internalActive: true
  }))
  assert.equal(s.internalMonitor, "eDP-1")
  assert.equal(s.cm.includes("<"), false)
  assert.equal(s.cm.includes(">"), false)
  assert.equal(s.cmOk, false)
  assert.equal(s.psrState, "unknown")
  assert.equal(s.gamma, 10)
  assert.equal(s.savedGamma, 100)
  assert.equal(clampBrightness(5), 10)
  assert.equal(parseState("not json"), null)
})
