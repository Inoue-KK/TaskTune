//
//  WidgetThemeEditView.swift
//  todo-list
//

import SwiftUI
import WidgetKit

struct WidgetThemeEditView: View {
    @State private var theme: WidgetTheme
    @State private var previewSize: PreviewSize = .medium
    @State private var availableWidth: CGFloat = 329
    @State private var availableHeight: CGFloat = 600
    @State private var showNameError = false
    @State private var scrollToName = false

    let onSave: (WidgetTheme) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private static let previewData = WidgetPreviewData()

    enum PreviewSize: String, CaseIterable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"
    }

    init(theme: WidgetTheme, onSave: @escaping (WidgetTheme) -> Void) {
        var resolved = theme
        if resolved.backgroundColorComponents == nil {
            resolved.backgroundColorComponents = ColorComponents.from(Color(.systemBackground))
        }
        if resolved.textColorComponents == nil {
            resolved.textColorComponents = ColorComponents.from(Color(.label))
        }
        if resolved.customFontSizePoints == nil {
            resolved.customFontSizePoints = switch resolved.fontSize {
            case .small: 12
            case .medium: 15
            case .large: 17
            }
        }
        self._theme = State(initialValue: resolved)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Group {
                if verticalSizeClass == .compact {
                    // 横向き: 左42%にプレビュー、右58%に設定リスト
                    HStack(spacing: 0) {
                        previewPanel
                            .containerRelativeFrame(.horizontal) { w, _ in w * 0.42 }
                            .frame(maxHeight: .infinity)
                        settingsPanel
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { availableHeight = $0 }
                } else {
                    // 縦向き: 上にプレビュー、下に設定リスト
                    VStack(spacing: 0) {
                        previewPanel
                        settingsPanel
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.clear, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if theme.name.trimmingCharacters(in: .whitespaces).isEmpty {
                            showNameError = true
                            scrollToName = true
                        } else {
                            onSave(theme)
                            dismiss()
                        }
                    }
                    .disabled(theme.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: - Panels

    private var previewPanel: some View {
        VStack(spacing: 16) {
            Color.clear
                .frame(height: 0)
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { availableWidth = $0 }
            // カスタムサイズピッカー
            HStack(spacing: 6) {
                ForEach(PreviewSize.allCases, id: \.self) { size in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            previewSize = size
                        }
                    } label: {
                        Text(size.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(previewSize == size ? .white : Color(.secondaryLabel))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 7)
                            .background(
                                previewSize == size
                                    ? theme.accentColorComponents.color
                                    : Color(.tertiarySystemFill),
                                in: Capsule()
                            )
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: previewSize)
                    }
                    .buttonStyle(.plain)
                }
            }

            previewContent
                .shadow(color: theme.accentColorComponents.color.opacity(0.25), radius: 16, y: 8)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .center)))
                .id(previewSize)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, maxHeight: verticalSizeClass == .compact ? .infinity : nil, alignment: .top)
        .background {
            ZStack {
                Color(.secondarySystemBackground)
                theme.accentColorComponents.color
                    .opacity(0.08)
            }
            .ignoresSafeArea(edges: verticalSizeClass == .compact ? [.leading, .top, .bottom] : [])
            .animation(.easeInOut(duration: 0.4), value: theme.accentColorComponents.color)
        }
    }

    private var settingsPanel: some View {
        ScrollViewReader { proxy in
            List {
                Section(
                    header: Text("Theme Name"),
                    footer: Group {
                        if showNameError {
                            Text("Name is required.")
                                .foregroundStyle(.red)
                        }
                    }
                ) {
                    TextField("Enter a name", text: $theme.name)
                        .onChange(of: theme.name) { _, _ in
                            if !theme.name.trimmingCharacters(in: .whitespaces).isEmpty {
                                showNameError = false
                            }
                        }
                }
                .id("nameField")

                Section("Colors") {
                    colorPickerRow("Accent Color", selection: accentColorBinding)
                    colorPickerRow("Background Color", selection: backgroundColorBinding)
                    colorPickerRow("Text Color", selection: textColorBinding)
                }

                Section("Layout") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Font Size")
                            Spacer()
                            Text("\(Int(fontSizePoints)) pt")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: fontSizeBinding, in: 8...32, step: 1)
                    }
                    .padding(.vertical, 4)
                    Picker("Row Height", selection: $theme.rowHeight) {
                        ForEach(WidgetRowHeightValue.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    Picker("Checkbox Position", selection: $theme.checkboxPosition) {
                        ForEach(WidgetCheckboxPositionValue.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    Picker("Style", selection: $theme.checkboxStyle) {
                        ForEach(WidgetCheckboxStyleValue.allCases, id: \.self) { style in
                            Label(style.displayName, systemImage: style.pendingIcon).tag(style)
                        }
                    }
                }

                Section("Display") {
                    Toggle("Show Remaining Count", isOn: $theme.showRemainingCount)
                    Toggle("Show Completed Count", isOn: $theme.showCompletedCount)
                    Toggle("Show Completed (Large only)", isOn: $theme.showCompleted)
                }
            }
            .listStyle(.insetGrouped)
            .onChange(of: scrollToName) { _, newValue in
                if newValue {
                    withAnimation { proxy.scrollTo("nameField", anchor: .top) }
                    scrollToName = false
                }
            }
        }
    }

    // MARK: - Preview

    @ViewBuilder
    private var previewContent: some View {
        switch previewSize {
        case .small:
            SmallWidgetPreview(theme: theme, data: Self.previewData)
                .scaleEffect(scale(nativeWidth: 155, nativeHeight: 155), anchor: .center)
                .frame(width: 155 * scale(nativeWidth: 155, nativeHeight: 155),
                       height: 155 * scale(nativeWidth: 155, nativeHeight: 155))
        case .medium:
            MediumWidgetPreview(theme: theme, data: Self.previewData)
                .scaleEffect(scale(nativeWidth: 329, nativeHeight: 155), anchor: .center)
                .frame(width: 329 * scale(nativeWidth: 329, nativeHeight: 155),
                       height: 155 * scale(nativeWidth: 329, nativeHeight: 155))
        case .large:
            LargeWidgetPreview(theme: theme, data: Self.previewData)
                .scaleEffect(scale(nativeWidth: 329, nativeHeight: 345), anchor: .center)
                .frame(width: 329 * scale(nativeWidth: 329, nativeHeight: 345),
                       height: 345 * scale(nativeWidth: 329, nativeHeight: 345))
        }
    }

    /// 横向き時は UIKit の値（回転と同時に同期更新）からパネル幅を計算し、
    /// availableWidth（非同期更新）との min を取ることで、縦→横の回転直後の
    /// 最初の描画フレームでも古い値のままウィジェットがはみ出すのを防ぐ。
    private var effectiveAvailableWidth: CGFloat {
        guard verticalSizeClass == .compact else { return availableWidth }
        // セーフエリアを差し引いた実際のコンテンツ幅を使う
        let safeInsets = (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .windows.first { $0.isKeyWindow }?
            .safeAreaInsets) ?? .zero
        let contentWidth = UIScreen.main.bounds.width - safeInsets.left - safeInsets.right
        return min(contentWidth * 0.42 - 40, availableWidth)
    }

    private func scale(nativeWidth: CGFloat, nativeHeight: CGFloat) -> CGFloat {
        let widthScale = effectiveAvailableWidth / nativeWidth
        guard verticalSizeClass == .compact else {
            return min(1.0, widthScale)
        }
        // 横向き: 高さも考慮（ピッカー38pt + スペーシング32pt + パディング40pt = 110pt のオーバーヘッド）
        let heightScale = (availableHeight - 110) / nativeHeight
        return min(1.0, min(widthScale, max(0.3, heightScale)))
    }

    // MARK: - Font Size Bindings

    private var fontSizePoints: Double { theme.customFontSizePoints ?? 15 }

    private var fontSizeBinding: Binding<Double> {
        Binding(
            get: { theme.customFontSizePoints ?? 15 },
            set: { theme.customFontSizePoints = $0 }
        )
    }

    // MARK: - Color Picker Rows

    @ViewBuilder
    private func colorPickerRow(_ label: String, selection: Binding<Color>) -> some View {
        HStack {
            Text(label)
            Spacer()
            UIColorPickerButton(title: label, color: selection)
                .frame(width: 29, height: 29)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(Color(.separator), lineWidth: 0.5))
        }
    }

    // MARK: - Color Bindings

    private var accentColorBinding: Binding<Color> {
        Binding(
            get: { theme.accentColorComponents.color },
            set: { theme.accentColorComponents = ColorComponents.from($0) }
        )
    }

    private var backgroundColorBinding: Binding<Color> {
        Binding(
            get: { theme.backgroundColorComponents?.color ?? .white },
            set: { theme.backgroundColorComponents = ColorComponents.from($0) }
        )
    }

    private var textColorBinding: Binding<Color> {
        Binding(
            get: { theme.textColorComponents?.color ?? Color(.label) },
            set: { theme.textColorComponents = ColorComponents.from($0) }
        )
    }
}

// MARK: - UIColorPickerButton

/// UIColorPickerViewController をポップオーバーとして表示するボタン。
/// ColorPicker と異なり、タップ元のビューにアンカーされるため画面全体を覆わない。
private struct UIColorPickerButton: UIViewRepresentable {
    let title: String
    @Binding var color: Color

    func makeCoordinator() -> Coordinator { Coordinator(title: title, color: $color) }

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .custom)
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped(_:)), for: .touchUpInside)
        return button
    }

    func updateUIView(_ button: UIButton, context: Context) {
        button.backgroundColor = UIColor(color)
        context.coordinator.title = title
        context.coordinator.color = $color
    }

    final class Coordinator: NSObject, UIColorPickerViewControllerDelegate, UIPopoverPresentationControllerDelegate {
        var title: String
        var color: Binding<Color>

        init(title: String, color: Binding<Color>) {
            self.title = title
            self.color = color
        }

        @objc func tapped(_ sender: UIButton) {
            let picker = UIColorPickerViewController()
            picker.title = title
            picker.selectedColor = UIColor(color.wrappedValue)
            picker.supportsAlpha = false
            picker.delegate = self
            picker.modalPresentationStyle = .popover
            let ppc = picker.popoverPresentationController
            ppc?.sourceView = sender
            ppc?.sourceRect = sender.bounds
            ppc?.permittedArrowDirections = [.left, .right, .up, .down]
            ppc?.delegate = self

            guard let scene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first(where: { $0.activationState == .foregroundActive }),
                  let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
            var top = root
            while let p = top.presentedViewController { top = p }
            top.present(picker, animated: true)
        }

        func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
            self.color.wrappedValue = Color(color)
        }

        // iPhone でもポップオーバーのままにする（シートに適応させない）
        func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle { .none }
        func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle { .none }
    }
}
