//
//  WidgetThemeListView.swift
//  todo-list
//

import SwiftUI
import WidgetKit

struct WidgetThemeListView: View {
    @State private var themes: [WidgetTheme] = WidgetThemeStore.loadAll()
    @State private var newTheme: WidgetTheme?
    @State private var themeToDelete: WidgetTheme?

    private static let previewData = WidgetPreviewData()

    var body: some View {
        Group {
            if themes.isEmpty {
                emptyState
            } else {
                themeList
            }
        }
        .navigationTitle("Widget Themes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newTheme = WidgetTheme(
                        id: UUID(),
                        name: defaultThemeName(),
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
        .alert("Delete \"\(themeToDelete?.name ?? "")\"?", isPresented: Binding(get: { themeToDelete != nil }, set: { if !$0 { themeToDelete = nil } })) {
            Button("Delete", role: .destructive) {
                if let theme = themeToDelete,
                   let index = themes.firstIndex(where: { $0.id == theme.id }) {
                    themes.remove(at: index)
                    if themes.isEmpty { themes = [.default] }
                    save()
                }
                themeToDelete = nil
            }
            Button("Cancel", role: .cancel) { themeToDelete = nil }
        }
        .sheet(item: $newTheme) { theme in
            NavigationStack {
                WidgetThemeEditView(theme: theme, isModal: true) { updatedTheme in
                    themes.append(updatedTheme)
                    save()
                }
            }
        }
    }

    // MARK: - Theme List

    private var themeList: some View {
        List {
            ForEach(themes) { theme in
                NavigationLink {
                    WidgetThemeEditView(theme: theme) { updatedTheme in
                        if let index = themes.firstIndex(where: { $0.id == updatedTheme.id }) {
                            themes[index] = updatedTheme
                        }
                        save()
                    }
                } label: {
                    HStack(spacing: 14) {
                        thumbnail(for: theme)
                        Text(theme.name)
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 4)
                }
                .alignmentGuide(.listRowSeparatorLeading) { d in d[.leading] }
                .swipeActions(edge: .trailing) {
                    Button {
                        themeToDelete = theme
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
                }
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
            Text("No themes yet")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            Text("Tap the + button to create one")
                .font(.subheadline)
                .foregroundStyle(Color(.systemGray3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Default Name

    private func defaultThemeName() -> String {
        let base = NSLocalizedString("New Theme", comment: "")
        let existing = Set(themes.map(\.name))
        if !existing.contains(base) { return base }
        var i = 2
        while existing.contains("\(base) \(i)") { i += 1 }
        return "\(base) \(i)"
    }

    // MARK: - Save

    private func save() {
        WidgetThemeStore.saveAll(themes)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
