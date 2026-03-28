//
//  WidgetThemeListView.swift
//  todo-list
//

import SwiftUI
import WidgetKit

struct WidgetThemeListView: View {
    @State private var themes: [WidgetTheme] = WidgetThemeStore.loadAll()
    @State private var editingTheme: WidgetTheme?

    @Environment(\.dismiss) private var dismiss

    private static let previewData = WidgetPreviewData()

    var body: some View {
        NavigationStack {
            Group {
                if themes.isEmpty {
                    emptyState
                } else {
                    themeList
                }
            }
            .navigationTitle("ウィジェットテーマ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("完了") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editingTheme = WidgetTheme(
                            id: UUID(),
                            name: "",
                            accentColorComponents: ColorComponents(red: 0, green: 0.478, blue: 1.0, opacity: 1.0),
                            backgroundColorComponents: nil,
                            textColorComponents: nil,
                            fontSize: .medium,
                            rowHeight: .normal,
                            checkboxPosition: .leading,
                            showRemainingCount: true,
                            showCompletedCount: false,
                            showCompleted: false
                        )
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(item: $editingTheme) { theme in
            WidgetThemeEditView(theme: theme) { updatedTheme in
                if let index = themes.firstIndex(where: { $0.id == updatedTheme.id }) {
                    themes[index] = updatedTheme
                } else {
                    themes.append(updatedTheme)
                }
                save()
            }
        }
    }

    // MARK: - Theme List

    private var themeList: some View {
        List {
            ForEach(themes) { theme in
                Button {
                    editingTheme = theme
                } label: {
                    HStack(spacing: 14) {
                        thumbnail(for: theme)
                        Text(theme.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete { indexSet in
                themes.remove(atOffsets: indexSet)
                if themes.isEmpty {
                    themes = [.default]
                }
                save()
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Thumbnail

    private func thumbnail(for theme: WidgetTheme) -> some View {
        SmallWidgetPreview(theme: theme, data: Self.previewData)
            .frame(width: 155, height: 155)
            .scaleEffect(52.0 / 155.0)
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "paintpalette")
                .font(.system(size: 64))
                .foregroundStyle(Color(.systemGray3))
            Text("テーマがありません")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            Text("＋ボタンからテーマを作成してください")
                .font(.subheadline)
                .foregroundStyle(Color(.systemGray3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Save

    private func save() {
        WidgetThemeStore.saveAll(themes)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
