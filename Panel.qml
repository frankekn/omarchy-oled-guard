import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons
import qs.Commons as Commons
import "OledGuardState.js" as GuardState

Panel {
  id: root
  moduleName: "io.github.frankekn.oled-guard"
  ipcTarget: "oled.guard"
  manageIpc: false

  readonly property string helperBin: decodeURIComponent(String(Qt.resolvedUrl("bin/oled-dc-brightness")).replace(/^file:\/\//, ""))
  readonly property int pollMs: Math.max(0, Number(root.setting("pollInterval", 5000)) || 0)
  readonly property color foreground: bar ? bar.foreground : Commons.Color.foreground
  readonly property color urgent: bar ? bar.urgent : Commons.Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.45)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  property var guardState: GuardState.DEFAULT_STATE
  property int brightnessPercent: 100
  property int pendingBrightnessPercent: 100
  property bool brightnessSetQueued: false
  property bool brightnessDragging: false
  property int brightnessRevision: 0
  property bool stateRefreshQueued: false
  property bool healAttemptedForCurrentDrift: false
  property real wheelAccumulator: 0
  property int cursorRow: 0
  property bool cursorActive: false

  readonly property var appearance: GuardState.barAppearance(root.guardState)
  readonly property int minBrightness: root.guardState.dcEnabled ? 10 : 1

  Commons.Translations {
    id: strings
    directory: Qt.resolvedUrl("i18n")
  }

  readonly property string statusSubtitle: {
    if (!root.guardState.internalActive) return strings.t("status.clamshell")
    if (!root.guardState.dcEnabled) return strings.t("status.off")
    if (!root.guardState.healthy) return strings.t("status.issue")
    return strings.t("status.on").arg(Commons.I18n.formatNumber(root.brightnessPercent))
  }

  readonly property string tooltip: GuardState.sanitizeText(strings.t("title") + " — " + root.statusSubtitle)

  onTooltipChanged: if (button.tooltipHovered && root.bar) root.bar.showTooltip(button, root.tooltip)

  ShellIpc {
    target: "oled.guard"

    function state(): string {
      return JSON.stringify({
        state: root.guardState,
        appearance: root.appearance
      })
    }
    function open() { root.open() }
    function close() { root.close() }
    function toggle() { root.toggle() }
    function show() { root.open() }
    function hide() { root.close() }
    function repair(): string { root.runAction(["repair"]); return "ok" }
  }

  function refresh() {
    if (stateProc.running) stateRefreshQueued = true
    else stateProc.running = true
  }

  function setBrightness(value) {
    var percent = GuardState.clampBrightness(value, root.minBrightness)
    root.brightnessRevision++
    root.brightnessPercent = percent
    root.pendingBrightnessPercent = percent

    if (setBrightnessProc.running) {
      root.brightnessSetQueued = true
      return
    }

    root.brightnessSetQueued = false
    setBrightnessProc.command = ["bash", root.helperBin, "--no-osd", "--monitor", root.guardState.internalMonitor, percent + "%"]
    setBrightnessProc.running = true
  }

  function previewBrightness(value) {
    root.brightnessRevision++
    root.brightnessPercent = GuardState.clampBrightness(value, root.minBrightness)
    brightnessDebounce.restart()
  }

  function showBrightnessOsd(percent) {
    if (!bar || !bar.shell) return
    bar.shell.summon("omarchy.osd", JSON.stringify({
      icon: "brightness",
      value: percent
    }))
  }

  function runAction(argv) {
    if (actionProc.running) return
    var full = ["bash", root.helperBin]
    for (var i = 0; i < argv.length; i++) full.push(argv[i])
    actionProc.command = full
    actionProc.running = true
  }

  function toggleDc() {
    root.healAttemptedForCurrentDrift = false
    root.runAction(["dc", root.guardState.dcEnabled ? "off" : "on"])
  }

  function toggleGamut() {
    root.runAction(["gamut", root.guardState.cmOk ? "off" : "on"])
  }

  function toggleWarmth() {
    root.runAction(["warmth", root.guardState.warmthOn ? "off" : "on"])
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Component.onCompleted: refresh()

  onOpenedChanged: {
    if (opened) {
      if (root.guardState.needsHeal) {
        root.healAttemptedForCurrentDrift = false
        root.runAction(["repair"])
      } else {
        refresh()
      }
      cursorRow = 0
      cursorActive = false
    } else {
      brightnessDragging = false
    }
  }

  Timer {
    interval: root.pollMs > 0 ? root.pollMs : 5000
    running: root.pollMs > 0
    repeat: true
    onTriggered: root.refresh()
  }

  Timer {
    id: brightnessDebounce
    interval: 150
    repeat: false
    onTriggered: root.setBrightness(root.brightnessPercent)
  }

  Process {
    id: stateProc
    property int revisionAtStart: 0
    command: ["bash", root.helperBin, "json"]
    onRunningChanged: if (running) revisionAtStart = root.brightnessRevision
    onExited: {
      if (root.stateRefreshQueued) {
        root.stateRefreshQueued = false
        root.refresh()
      }
    }
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var parsed = GuardState.parseState(text)
        if (!parsed) return
        if (stateProc.revisionAtStart === root.brightnessRevision
            && !root.brightnessDragging && !brightnessDebounce.running && !setBrightnessProc.running) {
          root.brightnessPercent = parsed.gamma
        }
        if (parsed.needsHeal && !root.healAttemptedForCurrentDrift && !autoHealProc.running && !actionProc.running) {
          root.healAttemptedForCurrentDrift = true
          autoHealProc.running = true
          return
        }
        if (!parsed.needsHeal) {
          root.healAttemptedForCurrentDrift = false
        }
        root.guardState = parsed
      }
    }
  }

  Process {
    id: autoHealProc
    command: ["bash", root.helperBin, "autoheal"]
    stdout: StdioCollector { waitForEnd: true }
    onExited: root.refresh()
  }

  Process {
    id: setBrightnessProc
    stdout: StdioCollector { waitForEnd: true }
    onRunningChanged: {
      if (running) return
      if (root.brightnessSetQueued) {
        root.setBrightness(root.pendingBrightnessPercent)
      } else {
        root.refresh()
      }
    }
  }

  Process {
    id: actionProc
    stdout: StdioCollector { waitForEnd: true }
    onExited: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.appearance.glyph
    dimmed: root.appearance.dimmed
    active: root.appearance.urgent
    activeColor: root.urgent
    tooltipText: root.tooltip
    onPressed: function(b) {
      if (b === Qt.RightButton) root.toggleDc()
      else root.toggle()
    }
    onWheelMoved: function(delta) {
      if (!root.guardState.internalActive) return
      var wheel = Util.wheelSteps(root.wheelAccumulator, delta)
      root.wheelAccumulator = wheel.remainder
      if (wheel.steps === 0) return
      root.setBrightness(root.brightnessPercent + wheel.steps * 5)
      root.showBrightnessOsd(root.brightnessPercent)
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Style.space(350))
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight, Style.space(520))

    content: PanelKeyCatcher {
      implicitHeight: panelColumn.implicitHeight
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        root.cursorActive = true
        if (dy !== 0) {
          root.cursorRow = Math.max(0, Math.min(3, root.cursorRow + (dy > 0 ? 1 : -1)))
        } else if (dx !== 0 && root.cursorRow === 0 && root.guardState.internalActive) {
          root.setBrightness(root.brightnessPercent + dx * 5)
        }
      }
      onActivateRequested: {
        if (!root.cursorActive) return
        if (root.cursorRow === 1) root.toggleDc()
        else if (root.cursorRow === 2) root.toggleGamut()
        else if (root.cursorRow === 3) root.toggleWarmth()
      }
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: panelColumn
        width: parent.width
        spacing: Style.space(10)

        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight)

          PlainText {
            id: heroIcon
            text: root.appearance.glyph
            color: root.appearance.urgent ? root.urgent : (root.appearance.dimmed ? root.dim : root.foreground)
            font.family: root.fontFamily
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            PlainText {
              text: strings.t("title")
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            PlainText {
              text: root.statusSubtitle
              color: root.appearance.urgent ? root.urgent : root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }
          }
        }

        PanelSeparator {
          visible: root.guardState.internalActive
          foreground: root.foreground
        }

        Column {
          visible: root.guardState.internalActive
          width: parent.width
          spacing: Style.space(6)

          Item {
            width: parent.width
            implicitHeight: Math.max(brightHeader.implicitHeight, brightLabel.implicitHeight)

            PanelSectionHeader {
              id: brightHeader
              text: strings.t("section.brightness")
              foreground: root.foreground
              fontFamily: root.fontFamily
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            PlainText {
              id: brightLabel
              text: Commons.I18n.formatNumber(Math.round(dcSlider.dragging ? dcSlider.liveValue : root.brightnessPercent)) + "%"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              anchors.right: parent.right
              anchors.rightMargin: Style.space(6)
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          CursorSurface {
            width: parent.width
            height: dcSlider.implicitHeight + Style.spacing.controlGap
            hasCursor: root.cursorActive && root.cursorRow === 0
            foreground: root.foreground
            outline: true

            PanelSlider {
              id: dcSlider
              bar: root.bar
              onDraggingChanged: root.brightnessDragging = dragging
              anchors.fill: parent
              anchors.leftMargin: Style.space(6)
              anchors.rightMargin: Style.space(6)
              minimum: root.minBrightness
              maximum: 100
              step: 1
              value: root.brightnessPercent
              integer: true
              onMoved: function(v) { root.previewBrightness(v) }
              onReleased: function(v) {
                brightnessDebounce.stop()
                root.setBrightness(v)
              }
            }

            HoverHandler {
              onHoveredChanged: if (hovered) {
                root.cursorActive = true
                root.cursorRow = 0
              }
            }
          }
        }

        PanelSeparator {
          visible: root.guardState.internalActive
          foreground: root.foreground
        }

        Column {
          visible: root.guardState.internalActive
          width: parent.width
          spacing: Style.space(8)

          Toggle {
            width: parent.width
            label: strings.t("toggle.dc.title")
            description: strings.t("toggle.dc.desc")
            checked: root.guardState.dcEnabled && root.guardState.healthy
            foreground: root.foreground
            fontFamily: root.fontFamily
            hasCursor: root.cursorActive && root.cursorRow === 1
            onHovered: function(h) { if (h) { root.cursorActive = true; root.cursorRow = 1 } }
            onClicked: root.toggleDc()
          }

          Toggle {
            width: parent.width
            label: strings.t("toggle.gamut.title")
            description: strings.t("toggle.gamut.desc")
            checked: root.guardState.cmOk
            foreground: root.foreground
            fontFamily: root.fontFamily
            hasCursor: root.cursorActive && root.cursorRow === 2
            onHovered: function(h) { if (h) { root.cursorActive = true; root.cursorRow = 2 } }
            onClicked: root.toggleGamut()
          }

          Toggle {
            width: parent.width
            label: strings.t("toggle.warmth.title")
            description: strings.t("toggle.warmth.desc")
            checked: root.guardState.warmthOn
            foreground: root.foreground
            fontFamily: root.fontFamily
            hasCursor: root.cursorActive && root.cursorRow === 3
            onHovered: function(h) { if (h) { root.cursorActive = true; root.cursorRow = 3 } }
            onClicked: root.toggleWarmth()
          }
        }

        PlainText {
          visible: root.guardState.internalActive && root.guardState.psrState === "pending_reboot"
          width: parent.width
          text: strings.t("footer.reboot")
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }
      }
    }
  }

  component PlainText: Text {
    textFormat: Text.PlainText
  }
}
