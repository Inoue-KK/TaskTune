//
//  WidgetPreviewViews.swift
//  todo-list
//
//  WidgetKit専用APIを使わないウィジェットプレビュー用ビュー
//  （Button(intent:)の代わりに非インタラクティブ表示、containerBackground不使用）
//

import SwiftUI

// MARK: - Preview Layout Constants

private enum WidgetPreviewSize {
    // Widget canvas dimensions (points)
    static let smallSide: CGFloat = 155
    static let mediumWidth: CGFloat = 329
    static let mediumHeight: CGFloat = 155
    static let largeWidth: CGFloat = 329
    static let largeHeight: CGFloat = 345
    static let cornerRadius: CGFloat = 22

    // Usable item area heights after subtracting padding, header, and divider
    // Small:  155 - 24 (v-padding) - 18 (header) - 2 (divider) ≈ 111
    // Medium: 155 - 24 (v-padding) - 14 (header) - 3 (divider) ≈ 114
    // Large:  345 - 32 (padding) - 36 (header) - 16 (divider) ≈ 261
    static let smallItemAreaHeight: CGFloat = 111
    static let mediumItemAreaHeight: CGFloat = 114
    static let largeItemAreaHeight: CGFloat = 261
}

// MARK: - Preview Data

struct WidgetPreviewData {
    var listTitle: String = NSLocalizedString("My List", comment: "")
    var pendingTodos: [String] = [
        NSLocalizedString("Buy groceries", comment: ""),
        NSLocalizedString("Call dentist", comment: ""),
        NSLocalizedString("Read book", comment: ""),
        NSLocalizedString("Exercise", comment: ""),
        NSLocalizedString("Reply to emails", comment: ""),
        NSLocalizedString("Clean the desk", comment: ""),
        NSLocalizedString("Plan weekend trip", comment: ""),
        NSLocalizedString("Fix kitchen light", comment: ""),
        NSLocalizedString("Water the plants", comment: ""),
        NSLocalizedString("Schedule haircut", comment: ""),
        NSLocalizedString("Renew subscription", comment: ""),
        NSLocalizedString("Backup photos", comment: ""),
    ]
    var completedTodos: [String] = [
        NSLocalizedString("Wake up", comment: ""),
        NSLocalizedString("Make coffee", comment: ""),
        NSLocalizedString("Morning run", comment: ""),
        NSLocalizedString("Take vitamins", comment: ""),
        NSLocalizedString("Check calendar", comment: ""),
    ]

    var totalPending: Int { pendingTodos.count }
    var totalCompleted: Int { completedTodos.count }
}

// MARK: - Preview Row View

private struct PreviewRowView: View {
    let title: String
    let isCompleted: Bool
    let theme: WidgetTheme
    var showCheckbox: Bool = true

    private var checkbox: some View {
        Image(systemName: isCompleted ? theme.checkboxStyle.completedIcon : theme.checkboxStyle.pendingIcon)
            .font(theme.iconFont)
            .foregroundStyle(isCompleted ? theme.secondaryTextColor : theme.accentColor)
    }

    var body: some View {
        HStack(spacing: 8) {
            if showCheckbox && theme.checkboxPosition == .leading { checkbox }
            Text(title)
                .font(theme.itemFont)
                .lineLimit(1)
                .foregroundStyle(isCompleted ? theme.secondaryTextColor : theme.textColor)
                .strikethrough(isCompleted)
            Spacer()
            if showCheckbox && theme.checkboxPosition == .trailing { checkbox }
        }
        .padding(.vertical, theme.rowHeight.verticalPadding)
    }
}

// MARK: - Preview Header View

private struct PreviewHeaderView: View {
    let data: WidgetPreviewData
    let theme: WidgetTheme

    var body: some View {
        HStack {
            Text(data.listTitle)
                .font(theme.headerFont)
                .foregroundStyle(theme.textColor)
                .lineLimit(1)
            Spacer()
            HStack(spacing: 6) {
                if theme.showRemainingCount {
                    Text("\(data.totalPending) left")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryTextColor)
                }
                if theme.showCompletedCount {
                    Text("\(data.totalCompleted) done")
                        .font(.caption)
                        .foregroundStyle(theme.tertiaryTextColor)
                }
            }
        }
        .padding(.bottom, 1)
    }
}

// MARK: - Small Widget Preview

struct SmallWidgetPreview: View {
    let theme: WidgetTheme
    let data: WidgetPreviewData

    private var maxItemCount: Int {
        max(1, Int(WidgetPreviewSize.smallItemAreaHeight / theme.estimatedRowHeight))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PreviewHeaderView(data: data, theme: theme)
            Divider().padding(.bottom, 1)
            pendingList
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(width: WidgetPreviewSize.smallSide, height: WidgetPreviewSize.smallSide)
        .background(theme.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: WidgetPreviewSize.cornerRadius))
    }

    @ViewBuilder
    private var pendingList: some View {
        let toShow = Array(data.pendingTodos.prefix(maxItemCount))
        let remaining = data.totalPending - toShow.count

        VStack(alignment: .leading, spacing: 0) {
            if data.pendingTodos.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("All done!").font(.caption).foregroundStyle(theme.secondaryTextColor)
                }
            } else {
                ForEach(Array(toShow.enumerated()), id: \.offset) { _, title in
                    PreviewRowView(title: title, isCompleted: false, theme: theme, showCheckbox: true)
                }
                if remaining > 0 {
                    Text("+ \(remaining) more")
                        .font(.caption2)
                        .foregroundStyle(theme.tertiaryTextColor)
                        .padding(.top, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Medium Widget Preview

struct MediumWidgetPreview: View {
    let theme: WidgetTheme
    let data: WidgetPreviewData

    private var maxItemCount: Int {
        max(1, Int(WidgetPreviewSize.mediumItemAreaHeight / theme.estimatedRowHeight))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PreviewHeaderView(data: data, theme: theme)
            Divider().padding(.bottom, 1)
            pendingList
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: WidgetPreviewSize.mediumWidth, height: WidgetPreviewSize.mediumHeight)
        .background(theme.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: WidgetPreviewSize.cornerRadius))
    }

    @ViewBuilder
    private var pendingList: some View {
        let toShow = Array(data.pendingTodos.prefix(maxItemCount))
        let remaining = data.totalPending - toShow.count

        VStack(alignment: .leading, spacing: 0) {
            if data.pendingTodos.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("All done!").font(.subheadline).foregroundStyle(theme.secondaryTextColor)
                }
            } else {
                ForEach(Array(toShow.enumerated()), id: \.offset) { _, title in
                    PreviewRowView(title: title, isCompleted: false, theme: theme)
                }
                if remaining > 0 {
                    Text("+ \(remaining) more")
                        .font(.caption)
                        .foregroundStyle(theme.tertiaryTextColor)
                        .padding(.top, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Large Widget Preview

struct LargeWidgetPreview: View {
    let theme: WidgetTheme
    let data: WidgetPreviewData

    private var innerHeight: CGFloat { WidgetPreviewSize.largeItemAreaHeight }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PreviewHeaderView(data: data, theme: theme)
            Divider().padding(.bottom, 8)
            todoList
        }
        .padding()
        .frame(width: WidgetPreviewSize.largeWidth, height: WidgetPreviewSize.largeHeight)
        .background(theme.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: WidgetPreviewSize.cornerRadius))
    }

    @ViewBuilder
    private var todoList: some View {
        let showCompletedSection = theme.showCompleted && !data.completedTodos.isEmpty
        let rowH = theme.estimatedRowHeight
        let pendingHeight: CGFloat = showCompletedSection ? innerHeight * 0.6 : innerHeight
        let completedHeight: CGFloat = innerHeight * 0.4
        let pendingCount = max(1, Int(pendingHeight / rowH))
        let completedCount = max(1, Int(completedHeight / rowH))
        let pendingToShow = Array(data.pendingTodos.prefix(pendingCount))
        let remaining = data.totalPending - pendingToShow.count

        VStack(alignment: .leading, spacing: 0) {
            if data.pendingTodos.isEmpty && !showCompletedSection {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("All done!").font(.subheadline).foregroundStyle(theme.secondaryTextColor)
                }
            } else {
                ForEach(Array(pendingToShow.enumerated()), id: \.offset) { _, title in
                    PreviewRowView(title: title, isCompleted: false, theme: theme)
                }
                if remaining > 0 {
                    Text("+ \(remaining) more")
                        .font(.caption)
                        .foregroundStyle(theme.tertiaryTextColor)
                        .padding(.top, 2)
                }
                if showCompletedSection {
                    Divider().padding(.vertical, 8)
                    ForEach(Array(data.completedTodos.prefix(completedCount).enumerated()), id: \.offset) { _, title in
                        PreviewRowView(title: title, isCompleted: true, theme: theme)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
