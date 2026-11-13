import SwiftUI
import AppKit

struct FocusView: View {
    @Bindable var store: FocusStore
    let controller: FocusWindowController
    @AppStorage("language") private var language = Locale.current.language.languageCode?.identifier == "zh" ? "zh" : "en"
    @AppStorage("appearance") private var appearance = "light"
    @FocusState private var focused: Field?
    @State private var dragPrevious: CGSize = .zero
    @State private var pinVisual = false
    enum Field: Hashable { case activity, goal }
    private var dark: Bool { appearance == "dark" }
    private var surface: Color { dark ? Color(red: 30/255, green: 30/255, blue: 30/255) : .white }
    private func lines(_ value: String) -> Int {
        max(2, min(7, value.components(separatedBy: "\n").reduce(0) { $0 + max(1, Int(ceil(Double($1.count) / 35))) }))
    }
    private func editorHeight(_ value: String) -> CGFloat { CGFloat(lines(value)) * 18 + 22 }
    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(Color(nsColor: .separatorColor).opacity(0.55)).frame(height: 0.5)
            VStack(alignment: .leading, spacing: 16) {
                field(Copy.text("我当下在做什么？", "What am I doing now?"), text: $store.activity, which: .activity)
                field(Copy.text("这件事的目标是什么？", "What is my goal?"), text: $store.goal, which: .goal)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .preferredColorScheme(dark ? .dark : .light)
        .onHover(perform: controller.panelHover)
        .onChange(of: focused) { _, new in controller.setEditing(new != nil) }
        .onChange(of: store.activity) { _, _ in resize() }
        .onChange(of: store.goal) { _, _ in resize() }
        .onReceive(NotificationCenter.default.publisher(for: .liteFocusPanelDidOpen)) { _ in focused = nil }
        .onReceive(NotificationCenter.default.publisher(for: .liteFocusEditorDidEnd)) { _ in focused = nil }
        .onAppear { pinVisual = controller.pinned; resize() }
    }
    private var header: some View {
        HStack(spacing: 10) {
            SproutMark(color: .white)
                .frame(width: 20, height: 20)
                .background(Color(red: 232/255, green: 181/255, blue: 26/255), in: Circle())
            Text("LiteFocus")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(nsColor: .labelColor))
            Spacer(minLength: 0)
            button("trash", help: Copy.text("清零", "Clear")) { store.clear(); focused = nil }
            button("globe", help: language == "zh" ? "Switch to English" : "切换到中文") { language = language == "zh" ? "en" : "zh" }
            button(dark ? "moon" : "sun.max", help: dark ? Copy.text("切换浅色模式", "Switch to Light") : Copy.text("切换深色模式", "Switch to Dark")) {
                controller.transitionAppearance { appearance = dark ? "light" : "dark" }
            }
            button(pinVisual ? "pin.fill" : "pin", help: pinVisual ? Copy.text("取消固定", "Unpin Panel") : Copy.text("固定浮窗", "Pin Panel")) { controller.togglePin(); pinVisual = controller.pinned }
            button("xmark", help: Copy.text("收起面板", "Close Panel"), hoverColor: .red, helpOffset: -32) { focused = nil; controller.dismissPanel(); pinVisual = false }
        }
        .padding(.horizontal, 16)
        .frame(height: 46)
        .zIndex(10)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 4).onChanged { value in
            let delta = CGSize(width: value.translation.width - dragPrevious.width, height: -(value.translation.height - dragPrevious.height))
            dragPrevious = value.translation
            controller.movePanel(by: NSSize(width: delta.width, height: delta.height), ended: false)
        }.onEnded { _ in dragPrevious = .zero; controller.movePanel(by: .zero, ended: true) })
    }
    private func button(_ symbol: String, help: String, hoverColor: Color = .primary, helpOffset: CGFloat = 0, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.primary)
        }
        .buttonStyle(FocusHeaderButtonStyle(hoverColor: hoverColor))
        .focusHelp(help, horizontalOffset: helpOffset)
    }
    private func field(_ label: String, text: Binding<String>, which: Field) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(dark ? Color.white : Color.black)
            TextEditor(text: text)
                .font(.system(size: 14))
                .foregroundStyle(Color(nsColor: .labelColor))
                .scrollContentBackground(.hidden)
                .padding(5)
                .frame(height: editorHeight(text.wrappedValue))
                .background(dark ? Color.white.opacity(0.06) : Color.black.opacity(0.035), in: RoundedRectangle(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 0.7))
                .focused($focused, equals: which)
                .simultaneousGesture(TapGesture().onEnded { focused = which })
                .accessibilityLabel(label)
        }
    }
    private func resize() {
        controller.resizePanel(height: 46 + 0.5 + 36 + 2 * 19 + 14 + editorHeight(store.activity) + editorHeight(store.goal) + 16)
    }
}


private struct SproutMark: View {
    let color: Color
    var body: some View {
        Canvas { context, size in
            var drawing = context
            drawing.scaleBy(x: size.width / 48, y: size.height / 48)
            var stem = Path()
            stem.move(to: CGPoint(x: 24, y: 34))
            stem.addLine(to: CGPoint(x: 24, y: 20))
            drawing.stroke(stem, with: .color(color), style: StrokeStyle(lineWidth: 2.7, lineCap: .round))
            var left = Path()
            left.move(to: CGPoint(x: 23.5, y: 23))
            left.addCurve(to: CGPoint(x: 15, y: 15), control1: CGPoint(x: 18, y: 22), control2: CGPoint(x: 15, y: 19))
            left.addCurve(to: CGPoint(x: 23.5, y: 23), control1: CGPoint(x: 20, y: 14), control2: CGPoint(x: 23, y: 18))
            left.closeSubpath()
            drawing.fill(left, with: .color(color))
            var right = Path()
            right.move(to: CGPoint(x: 24.5, y: 21))
            right.addCurve(to: CGPoint(x: 33, y: 13), control1: CGPoint(x: 26, y: 16), control2: CGPoint(x: 31, y: 13))
            right.addCurve(to: CGPoint(x: 24.5, y: 21), control1: CGPoint(x: 33, y: 19), control2: CGPoint(x: 29, y: 22))
            right.closeSubpath()
            drawing.fill(right, with: .color(color))
        }
        .accessibilityLabel(Copy.text("嫩芽", "Sprout"))
    }
}

private struct FocusHeaderButtonStyle: ButtonStyle {
    var hoverColor: Color = .primary

    func makeBody(configuration: Configuration) -> some View {
        FocusHeaderButtonBody(configuration: configuration, hoverColor: hoverColor)
    }

    private struct FocusHeaderButtonBody: View {
        let configuration: Configuration
        let hoverColor: Color
        @State private var hovering = false

        var body: some View {
            configuration.label
                .symbolRenderingMode(.monochrome)
                .frame(width: 28, height: 28)
                .background(
                    hoverColor.opacity(configuration.isPressed ? 0.12 : hovering ? 0.08 : 0),
                    in: RoundedRectangle(cornerRadius: 5, style: .continuous)
                )
                .contentShape(Rectangle())
                .onHover { hovering = $0 }
        }
    }
}

private struct FocusHelpModifier: ViewModifier {
    let text: String
    let horizontalOffset: CGFloat
    @State private var isPresented = false
    @State private var hoverToken = UUID()

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(text)
            .onHover { hovering in
                let token = UUID()
                hoverToken = token
                if hovering {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                        guard hoverToken == token else { return }
                        isPresented = true
                    }
                } else {
                    isPresented = false
                }
            }
            .overlay(alignment: .bottom) {
                if isPresented {
                    Text(text)
                        .font(.system(size: 10.5, weight: .regular))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                        }
                        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                        .offset(x: horizontalOffset, y: 28)
                        .allowsHitTesting(false)
                }
            }
            .zIndex(isPresented ? 20 : 0)
    }
}

private extension View {
    func focusHelp(_ text: String, horizontalOffset: CGFloat = 0) -> some View {
        modifier(FocusHelpModifier(text: text, horizontalOffset: horizontalOffset))
    }
}
