//
//  WidgetThemeEditView.swift
//  todo-list
//

import SwiftUI
import WidgetKit

struct WidgetThemeEditView: View {
    @State private var theme: WidgetTheme
    @State private var useCustomBackground: Bool
    @State private var useCustomTextColor: Bool
    @State private var previewSize: PreviewSize = .medium

    let onSave: (WidgetTheme) -> Void

    @Environment(\.dismiss) private var dismiss

    private static let previewData = WidgetPreviewData()

    enum PreviewSize: String, CaseIterable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"
    }

    init(theme: WidgetTheme, onSave: @escaping (WidgetTheme) -> Void) {
        self._theme = State(initialValue: theme)
        self._useCustomBackground = State(initialValue: theme.backgroundColorComponents != nil)
        self._useCustomTextColor = State(initialValue: theme.textColorComponents != nil)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // プレビュー（固定）
                VStack(spacing: 16) {
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
                    // テーマ名
                    Section("テーマ名") {
                        TextField("名前を入力", text: $theme.name)
                    }

                    // カラー設定
                    Section("カラー") {
                        ColorPicker("アクセントカラー", selection: accentColorBinding, supportsOpacity: false)

                        Toggle("背景色をカスタマイズ", isOn: $useCustomBackground)
                            .onChange(of: useCustomBackground) { _, newValue in
                                theme.backgroundColorComponents = newValue
                                    ? ColorComponents.from(.white)
                                    : nil
                            }
                        if useCustomBackground {
                            ColorPicker("背景色", selection: backgroundColorBinding, supportsOpacity: false)
                        }

                        Toggle("テキスト色をカスタマイズ", isOn: $useCustomTextColor)
                            .onChange(of: useCustomTextColor) { _, newValue in
                                theme.textColorComponents = newValue
                                    ? ColorComponents.from(Color(.label))
                                    : nil
                            }
                        if useCustomTextColor {
                            ColorPicker("テキスト色", selection: textColorBinding, supportsOpacity: false)
                        }
                    }

                    // レイアウト設定
                    Section("レイアウト") {
                        Picker("文字サイズ", selection: $theme.fontSize) {
                            ForEach(WidgetFontSizeValue.allCases, id: \.self) {
                                Text($0.displayName).tag($0)
                            }
                        }
                        Picker("行の高さ", selection: $theme.rowHeight) {
                            ForEach(WidgetRowHeightValue.allCases, id: \.self) {
                                Text($0.displayName).tag($0)
                            }
                        }
                        Picker("チェックボックス位置", selection: $theme.checkboxPosition) {
                            ForEach(WidgetCheckboxPositionValue.allCases, id: \.self) {
                                Text($0.displayName).tag($0)
                            }
                        }
                    }

                    // 表示設定
                    Section("表示") {
                        Toggle("残タスク数を表示", isOn: $theme.showRemainingCount)
                        Toggle("完了数を表示", isOn: $theme.showCompletedCount)
                        Toggle("完了済みも表示（Largeのみ）", isOn: $theme.showCompleted)
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle(theme.name.isEmpty ? "新しいテーマ" : theme.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
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
                .scaleEffect(mediumScale, anchor: .center)
                .frame(width: 329 * mediumScale, height: 155 * mediumScale)
        case .large:
            LargeWidgetPreview(theme: theme, data: Self.previewData)
                .scaleEffect(largeScale, anchor: .center)
                .frame(width: 329 * largeScale, height: 345 * largeScale)
        }
    }

    private var mediumScale: CGFloat {
        let available = UIScreen.main.bounds.width - 64
        return min(1.0, available / 329)
    }

    private var largeScale: CGFloat {
        let available = UIScreen.main.bounds.width - 64
        return min(1.0, available / 329)
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
