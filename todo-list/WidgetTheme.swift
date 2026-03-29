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

// MARK: - Checkbox Style

enum WidgetCheckboxStyleValue: String, Codable, CaseIterable {
    case circleDotted, circle, square, roundedSquare, diamond, seal, bubble, heart, star, bookmark

    var displayName: String {
        switch self {
        case .circleDotted:  "Dotted Circle"
        case .circle:        "Circle"
        case .square:        "Square"
        case .roundedSquare: "Rounded Square"
        case .diamond:       "Diamond"
        case .seal:          "Seal"
        case .bubble:        "Bubble"
        case .heart:         "Heart"
        case .star:          "Star"
        case .bookmark:      "Bookmark"
        }
    }

    var pendingIcon: String {
        switch self {
        case .circleDotted:  "circle.dotted"
        case .circle:        "circle"
        case .square:        "square"
        case .roundedSquare: "app"
        case .diamond:       "diamond"
        case .seal:          "seal"
        case .bubble:        "bubble"
        case .heart:         "heart"
        case .star:          "star"
        case .bookmark:      "bookmark"
        }
    }

    var completedIcon: String {
        switch self {
        case .circleDotted:  "checkmark.circle.fill"
        case .circle:        "checkmark.circle.fill"
        case .square:        "checkmark.square.fill"
        case .roundedSquare: "checkmark.app.fill"
        case .diamond:       "checkmark.diamond.fill"
        case .seal:          "checkmark.seal.fill"
        case .bubble:        "checkmark.bubble.fill"
        case .heart:         "heart.fill"
        case .star:          "star.fill"
        case .bookmark:      "bookmark.fill"
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
    var checkboxStyle: WidgetCheckboxStyleValue
    var showRemainingCount: Bool
    var showCompletedCount: Bool
    var showCompleted: Bool

    init(id: UUID, name: String, accentColorComponents: ColorComponents,
         backgroundColorComponents: ColorComponents?, textColorComponents: ColorComponents?,
         fontSize: WidgetFontSizeValue, rowHeight: WidgetRowHeightValue,
         checkboxPosition: WidgetCheckboxPositionValue,
         checkboxStyle: WidgetCheckboxStyleValue = .circleDotted,
         showRemainingCount: Bool, showCompletedCount: Bool, showCompleted: Bool) {
        self.id = id
        self.name = name
        self.accentColorComponents = accentColorComponents
        self.backgroundColorComponents = backgroundColorComponents
        self.textColorComponents = textColorComponents
        self.fontSize = fontSize
        self.rowHeight = rowHeight
        self.checkboxPosition = checkboxPosition
        self.checkboxStyle = checkboxStyle
        self.showRemainingCount = showRemainingCount
        self.showCompletedCount = showCompletedCount
        self.showCompleted = showCompleted
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        accentColorComponents = try c.decode(ColorComponents.self, forKey: .accentColorComponents)
        backgroundColorComponents = try c.decodeIfPresent(ColorComponents.self, forKey: .backgroundColorComponents)
        textColorComponents = try c.decodeIfPresent(ColorComponents.self, forKey: .textColorComponents)
        fontSize = try c.decode(WidgetFontSizeValue.self, forKey: .fontSize)
        rowHeight = try c.decode(WidgetRowHeightValue.self, forKey: .rowHeight)
        checkboxPosition = try c.decode(WidgetCheckboxPositionValue.self, forKey: .checkboxPosition)
        checkboxStyle = (try? c.decodeIfPresent(WidgetCheckboxStyleValue.self, forKey: .checkboxStyle)) ?? .circleDotted
        showRemainingCount = try c.decode(Bool.self, forKey: .showRemainingCount)
        showCompletedCount = try c.decode(Bool.self, forKey: .showCompletedCount)
        showCompleted = try c.decode(Bool.self, forKey: .showCompleted)
    }

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
