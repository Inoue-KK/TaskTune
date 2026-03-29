# todo-list

シンプルでモダンなデザインのiOS向けTodoリストアプリ。

## 技術スタック

- **言語:** Swift
- **UI:** SwiftUI
- **データ永続化:** SwiftData
- **対象プラットフォーム:** iOS 17+
- **最小構成:** Xcodeデフォルトテンプレートをベースに構築

## ファイル構成

```
todo-list/
├── todo_listApp.swift        # エントリポイント（App Group対応・WidgetKit連携）
├── TodoList.swift            # リストモデル（@Model）
├── Todo.swift                # TodoモデL（@Model、TodoListと親子関係）
├── WidgetTheme.swift         # ウィジェットテーマモデル（両ターゲット共通）
├── ListsView.swift           # ホーム画面（リスト一覧・ディープリンク対応）
├── ContentView.swift         # リスト詳細画面（Todo一覧・セクション分け）
├── AddListView.swift         # リスト追加シート
├── AddTodoView.swift         # Todo追加シート
├── RenameListView.swift      # リスト名変更シート
├── WidgetThemeListView.swift # ウィジェットテーマ一覧シート
├── WidgetThemeEditView.swift # ウィジェットテーマ編集（ColorPicker・プレビュー）
└── WidgetPreviewViews.swift  # ウィジェットプレビュー用ビュー（WidgetKit非依存）

TodoListWidget/
├── TodoListWidgetBundle.swift  # ウィジェットのエントリポイント（@main）
└── TodoListWidget.swift        # ウィジェット実装（Small/Medium/Large・インタラクティブ対応）

design/                   # アイコン制作用素材（Xcodeビルド対象外）
```

## 主な機能

- 複数のTodoリストを作成・管理（タイトル付き）
- リスト名の変更（一覧画面のスワイプ or 詳細画面のタイトルタップ）
- Todoの追加（シートUI）
- タップでチェックON/OFF（アニメーション付き）
- 「未完了」「完了」セクションへの自動振り分け
- スワイプで削除（リスト・Todo両対応）。リスト削除時は確認ダイアログを表示（全Todoが cascade delete されるため）
- ドラッグで並び替え（リスト一覧・Pending/Completedセクション内のTodo）
- エンプティステート表示
- ホーム画面ウィジェット（Small/Medium/Large）
  - 表示するリストをウィジェット設定で選択可能
  - ウィジェット設定でテーマを選択（アプリ内で作成したテーマを適用）
  - ウィジェット設定で操作モードを選択（「タップで完了」／「読み取り専用」）。全サイズ共通
  - 「タップで完了」モード時はチェックボックスをタップしてTodoを完了にできる（iOS 17 Interactive Widgets）
  - Todo完了タップはチェックボックス領域のみ受け付ける（誤タップ防止）
  - Todo完了時にチェックマークのフラッシュアニメーションを表示してからデータ更新
  - Smallウィジェットはヘッダー＋Todoリスト表示（Medium/Largeと同様のレイアウト、横パディング12pt）
  - ウィジェットタップで該当リストを直接開く（ディープリンク）
  - アプリがバックグラウンドに移行したタイミングでウィジェットを自動更新
  - iOS 26 Liquid Glass（Accented rendering mode）対応
- ウィジェットテーマ管理（ListsView右上のアイコンから）
  - アプリ内でテーマを作成・編集・削除
  - Small/Medium/Largeのリアルタイムプレビュー付き
  - アクセントカラー・背景色・テキスト色をColorPickerで自由に設定
  - 文字サイズ・行の高さ・チェックボックス位置・表示設定も編集可能
  - チェックボックスのデザインを10種類から選択可能（`WidgetCheckboxStyleValue`）
  - 複数テーマを保存し、ウィジェットごとに使い分け可能

## 設計方針

- SwiftDataで永続化。`TodoList` が `@Relationship(deleteRule: .cascade)` で `Todo` を管理
- リスト削除時にTodoも自動削除される
- `TodoList.sortOrder` と `Todo.sortOrder` で並び順を永続管理（ドラッグ並び替え時に更新）
- システムカラーを使用してダーク/ライトモードに自動対応
- UIの文言は英語に統一（ローカライズはリリース前にまとめて対応予定）
- 不要な抽象化を避け、最小限のコードで実装する
- App Group（`group.com.inoue-kk.todo-list`）経由でメインアプリとウィジェットがSwiftDataストアを共有
- ウィジェットとのディープリンクはURLスキーム `todolist://list/{リスト名}` を使用
- `ListsView` は `NavigationPath` でプログラマティックナビゲーションに対応
- `TodoList.swift`・`Todo.swift`・`WidgetTheme.swift` はメインアプリ（`todo-list`）・ウィジェット（`TodoListWidgetExtension`）両ターゲットに含める
- ウィジェットテーマは `WidgetTheme`（Codable）として App Group の UserDefaults（キー: `widgetThemes`）に JSON 保存
- テーマの色は `ColorComponents`（RGBA）で保存。`nil` の場合はシステムカラー（自動）を使用
- チェックボックスのデザインは `WidgetCheckboxStyleValue` enum（10種類）で管理し、テーマに含めて保存
- ウィジェットは `@Environment(\.widgetRenderingMode)` で `.accented` モードを検出し、iOS 26 Liquid Glass に対応
- ウィジェットプレビュー用ビュー（`WidgetPreviewViews.swift`）は WidgetKit 専用 API を使わず、メインアプリのみのターゲットに含める

## シートUI共通仕様

- `presentationDetents([.height(280)])` で固定高さ
- `presentationCornerRadius(20)` で角丸
- Add/Saveボタン：青のフルボタン（未入力時はグレーで非活性）
- Cancelボタン：セカンダリカラーのテキストボタン
