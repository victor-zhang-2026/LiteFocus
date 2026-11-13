# 安装与数据 / Install and data

## 系统要求 / Requirements

macOS 14+，Apple Silicon（arm64）。 / macOS 14+ on Apple Silicon (arm64).

## 安装 / Install

1. 在 [Releases](https://github.com/victor-zhang-2026/LiteFocus/releases/latest) 下载最新 `LiteFocus-<版本>-macOS-arm64.zip` 和 `SHA256SUMS`。
2. 同目录运行 `shasum -a 256 -c SHA256SUMS`。 / Verify the downloaded ZIP with the checksum file.
3. 解压后打开 `LiteFocus.app`，需要时拖入“应用程序”。 / Unzip and open the app; optionally move it to Applications.
4. 本包为 ad-hoc 签名，未经过 Apple 公证。首次打开可在 Finder 中右键点击应用并选择“打开”。 / The app is ad-hoc signed and not notarized. On first launch, right-click it in Finder and choose Open.

## 使用 / Use

黄色悬浮球可拖动。悬停展开面板；点击字段即可编辑。Pin 固定面板；右上角 × 收起并取消固定。Clear 立即清空两个字段。右键悬浮球可退出应用。

Drag the yellow ball to reposition it. Hover to open the panel and click a field to edit. Pin keeps the panel open; × closes it and clears Pin. Clear removes both values immediately. Right-click the ball to quit.

## 数据 / Data

事项、目标、Pin 状态、语言、外观和显示器相对位置保存在当前用户的 `~/Library/Preferences/io.github.victor-zhang-2026.litefocus.plist`。Clear 会删除事项与目标对应的偏好键；没有历史或自动备份。删除应用不会自动删除偏好文件。

The current activity, goal, Pin state, language, appearance, and display-relative position live in the current user's preference domain. Clear removes the two content keys. There is no history or automatic backup. Deleting the app does not delete preferences.

如要彻底卸载，退出应用，删除 App，并删除上述偏好文件。 / For complete removal, quit the app, delete the app bundle, then delete that preference file.
