//
//  WidgetTheme.swift
//  todo-list / TodoListWidget
//
//  両ターゲット（メインアプリ・ウィジェット）に含めること
//

import SwiftUI

// MARK: - Color Components

struct ColorComponents: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }

    static func from(_ color: Color) -> ColorComponents {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return ColorComponents(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
    }
}

// MARK: - Font Size

enum WidgetFontSizeValue: String, Codable, CaseIterable {
    case small, medium, large

    var displayName: String {
        switch self {
        case .small: "小"
        case .medium: "中（標準）"
        case .large: "大"
        }
    }

    var itemFont: Font {
        switch self {
        case .small: .caption
        case .medium: .subheadline
        case .large: .body
        }
    }

    var iconFont: Font {
        switch self {
        case .small: .caption2
        case .medium: .caption
        case .large: .subheadline
        }
    }

    var headerFont: Font {
        switch self {
        case .small: .subheadline
        case .medium: .headline
        case .large: .title3
        }
    }

    var lineHeight: CGFloat {
        switch self {
        case .small: 16
        case .medium: 20
        case .large: 22
        }
    }
}

// MARK: - Row Height

enum WidgetRowHeightValue: String, Codable, CaseIterable {
    case compact, normal, comfortable

    var displayName: String {
        switch self {
        case .compact: "コンパクト"
        case .normal: "標準"
        case .comfortable: "ゆったり"
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .compact: 2
        case .normal: 6
        case .comfortable: 11
        }
    }
}

// MARK: - Checkbox Position

enum WidgetCheckboxPositionValue: String, Codable, CaseIterable {
    case leading, trailing

    var displayName: String {
        switch self {
        case .leading: "左"
        case .trailing: "右"
        }
    }
}

// MARK: - Widget Theme

struct WidgetTheme: Codable, Identifiable {
    var id: UUID
    var name: String
    var accentColorComponents: ColorComponents
    var backgroundColorComponents: ColorComponents?
    var textColorComponents: ColorComponents?
    var fontSize: WidgetFontSizeValue
    var rowHeight: WidgetRowHeightValue
    var checkboxPosition: WidgetCheckboxPositionValue
    var showRemainingCount: Bool
    var showCompletedCount: Bool
    var showCompleted: Bool

    var accentColor: Color { accentColorComponents.color }
    var backgroundColor: Color { backgroundColorComponents?.color ?? Color(.systemBackground) }
    var textColor: Color { textColorComponents?.color ?? Color(.label) }
    var secondaryTextColor: Color {
        textColorComponents.map { $0.color.opacity(0.6) } ?? Color(.secondaryLabel)
    }
    var tertiaryTextColor: Color {
        textColorComponents.map { $0.color.opacity(0.4) } ?? Color(.tertiaryLabel)
    }

    var estimatedRowHeight: CGFloat {
        fontSize.lineHeight + rowHeight.verticalPadding * 2
    }

    static let `default` = WidgetTheme(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Default",
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
}

// MARK: - Theme Store

enum WidgetThemeStore {
    private static let appGroupID = "group.com.inoue-kk.todo-list"
    private static let key = "widgetThemes"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func loadAll() -> [WidgetTheme] {
        guard let data = defaults?.data(forKey: key),
              let themes = try? JSONDecoder().decode([WidgetTheme].self, from: data),
              !themes.isEmpty
        else { return [.default] }
        return themes
    }

    static func saveAll(_ themes: [WidgetTheme]) {
        guard let data = try? JSONEncoder().encode(themes) else { return }
        defaults?.set(data, forKey: key)
    }

    static func find(name: String?) -> WidgetTheme {
        let themes = loadAll()
        if let name, let found = themes.first(where: { $0.name == name }) {
            return found
        }
        return themes.first ?? .default
    }
}
