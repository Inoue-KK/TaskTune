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

    let onSave: (WidgetTheme) -> Void

    @Environment(\.dismiss) private var dismiss

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
        self._theme = State(initialValue: resolved)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // プレビュー（固定）
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
                .frame(maxWidth: .infinity)
                .background {
                    ZStack {
                        Color(.secondarySystemBackground)
                        theme.accentColorComponents.color
                            .opacity(0.08)
                    }
                    .animation(.easeInOut(duration: 0.4), value: theme.accentColorComponents.color)
                }

                // スクロール可能な設定リスト
                List {
                    Section("Theme Name") {
                        TextField("Enter a name", text: $theme.name)
                    }

                    Section("Colors") {
                        ColorPicker("Accent Color", selection: accentColorBinding, supportsOpacity: false)
                        ColorPicker("Background Color", selection: backgroundColorBinding, supportsOpacity: false)
                        ColorPicker("Text Color", selection: textColorBinding, supportsOpacity: false)
                    }

                    Section("Layout") {
                        Picker("Font Size", selection: $theme.fontSize) {
                            ForEach(WidgetFontSizeValue.allCases, id: \.self) {
                                Text($0.displayName).tag($0)
                            }
                        }
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
            }
            .navigationTitle(theme.name.isEmpty ? "New Theme" : theme.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(theme)
                        dismiss()
                    }
                    .disabled(theme.name.trimmingCharacters(in: .whitespaces).isEmpty)
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
        case .medium:
            MediumWidgetPreview(theme: theme, data: Self.previewData)
                .scaleEffect(scale, anchor: .center)
                .frame(width: 329 * scale, height: 155 * scale)
        case .large:
            LargeWidgetPreview(theme: theme, data: Self.previewData)
                .scaleEffect(scale, anchor: .center)
                .frame(width: 329 * scale, height: 345 * scale)
        }
    }

    private var scale: CGFloat {
        min(1.0, availableWidth / 329)
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
