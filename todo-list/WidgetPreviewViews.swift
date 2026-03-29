//
//  WidgetPreviewViews.swift
//  todo-list
//
//  WidgetKit専用APIを使わないウィジェットプレビュー用ビュー
//  （Button(intent:)の代わりに非インタラクティブ表示、containerBackground不使用）
//

import SwiftUI

// MARK: - Preview Data

struct WidgetPreviewData {
    var listTitle: String = "My List"
    var pendingTodos: [String] = ["Buy groceries", "Call dentist", "Read book", "Exercise"]
    var completedTodos: [String] = ["Wake up", "Make coffee"]

    var totalPending: Int { pendingTodos.count }
    var totalCompleted: Int { completedTodos.count }
}

// MARK: - Preview Row View

private struct PreviewRowView: View {
    let title: String
    let isCompleted: Bool
    let theme: WidgetTheme

    private var checkbox: some View {
        Image(systemName: isCompleted ? theme.checkboxStyle.completedIcon : theme.checkboxStyle.pendingIcon)
            .font(theme.fontSize.iconFont)
            .foregroundStyle(isCompleted ? theme.secondaryTextColor : theme.accentColor)
    }

    var body: some View {
        HStack(spacing: 8) {
            if theme.checkboxPosition == .leading { checkbox }
            Text(title)
                .font(theme.fontSize.itemFont)
                .lineLimit(1)
                .foregroundStyle(isCompleted ? theme.secondaryTextColor : theme.textColor)
                .strikethrough(isCompleted)
            Spacer()
            if theme.checkboxPosition == .trailing { checkbox }
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
                .font(theme.fontSize.headerFont)
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

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: data.totalPending == 0 ? "checkmark.circle.fill" : "circle.dotted")
                .font(.system(size: 32))
                .foregroundStyle(data.totalPending == 0 ? Color.green : theme.accentColor)

            Text("\(data.totalPending)")
                .font(.system(size: 48, weight: .bold))
                .minimumScaleFactor(0.5)
                .foregroundStyle(theme.textColor)

            Text(data.listTitle)
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor)
                .lineLimit(1)

            Text(data.totalPending == 1 ? "task left" : "tasks left")
                .font(.caption2)
                .foregroundStyle(theme.tertiaryTextColor)
        }
        .frame(width: 155, height: 155)
        .background(theme.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

// MARK: - Medium Widget Preview

struct MediumWidgetPreview: View {
    let theme: WidgetTheme
    let data: WidgetPreviewData

    private var maxItemCount: Int {
        max(1, Int(114 / theme.estimatedRowHeight))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PreviewHeaderView(data: data, theme: theme)
            Divider().padding(.bottom, 1)
            pendingList
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 329, height: 155)
        .background(theme.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 22))
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

    private let innerHeight: CGFloat = 261  // 345 - padding(16*2) - header(36) - divider(8)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PreviewHeaderView(data: data, theme: theme)
            Divider().padding(.bottom, 8)
            todoList
        }
        .padding()
        .frame(width: 329, height: 345)
        .background(theme.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 22))
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
