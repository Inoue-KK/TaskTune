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
├── Todo.swift                # Todoモデル（@Model、TodoListと親子関係）
├── WidgetTheme.swift         # ウィジェットテーマモデル（両ターゲット共通）
├── ListsView.swift           # ホーム画面（リスト一覧・ディープリンク対応）
├── ContentView.swift         # リスト詳細画面（Todo一覧・セクション分け）
├── SettingsView.swift        # 設定画面（Form・push遷移）
├── AddListView.swift         # リスト追加シート
├── AddTodoView.swift         # Todo追加シート（期日・繰り返し設定トグル付き）
├── EditTodoView.swift        # Todo編集シート（タイトル・期日・繰り返し変更）
├── NotificationManager.swift # UserNotifications管理（スケジュール・キャンセル・権限）
├── WeekdaySelectorView.swift # 曜日選択UI（Weekly繰り返し時に表示）
├── RenameListView.swift      # リスト名変更シート
├── WidgetThemeListView.swift # ウィジェットテーマ一覧（Settingsからpush遷移）
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
- Todoの追加（シートUI）。期日（日時）を設定可能なトグル付き。期日設定時に繰り返し間隔（Daily/Weekly/Monthly/Yearly）も選択可能。Daily/Monthly/Yearly は N 日/月/年ごとの Stepper で間隔指定可能。Weekly 選択時は曜日ボタン（WeekdaySelectorView）で複数曜日を指定可能。繰り返し設定時は終了条件（Never / After N repeats / On Date）も選択可能
- Todo行タップで編集シートを表示（タイトル・期日・繰り返しを変更可能）
- タップでチェックON/OFF（アニメーション付き）。完了時にサウンド・ハプティクスを発火（設定でON/OFF可能）。繰り返しなし完了時は期日通知をキャンセル、繰り返しあり完了時は次周期通知をキャンセルしない（missedCount=0にリセット）。未完了に戻した場合は再スケジュール
- 期日（dueDate）の表示：未完了Todoの行に期日ラベルを表示（期限切れ=赤、当日=オレンジ、将来=グレー）
- 繰り返しTodoの表示：行に🔁アイコンを表示。未達成回数が1以上の場合は「Missed ×N」ラベルを赤で表示
- 期日通知：UserNotifications（ローカル通知）。期日到達時にバナー通知。通知から「Mark Complete」アクションで直接完了可能。バナータップで該当リストへ遷移。アプリ起動時に通知権限を要求
- 繰り返しTodoの自動前進：アプリがフォアグラウンドに戻ったとき（scenePhase == .active）に期日超過した繰り返しTodoをスキャン。未完了は missedCount を加算して次周期へ前進、完了済みはリセットして次周期へ前進（Pending に戻す）
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
  - Smallウィジェットはヘッダー＋Todoリスト表示（Medium/Largeと同様のレイアウト、横パディング8pt）
  - 未設定時（`listTitle` が nil）は先頭リストにフォールバックせず、操作案内テキストを表示（`isSetup: true`）。Smallは `.caption` フォント＋折り返し、Medium/Largeは通常フォントで表示
  - ウィジェットタップで該当リストを直接開く（ディープリンク）
  - アプリがバックグラウンドに移行したタイミングでウィジェットを自動更新
  - iOS 26 Liquid Glass（Accented rendering mode）対応
- 設定画面（ListsView右上のギアアイコン → push遷移）
  - Sound・Haptic Feedbackのトグル（`@AppStorage` で永続化）
  - Sound有効時にSound Effect選択画面へのNavigationLink表示（タップでプレビュー再生）
  - About（バージョン情報）
- ウィジェットテーマ管理（設定画面 → Widget Themes）
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
- `ListsView` は `NavigationPath` でプログラマティックナビゲーションに対応。`.toolbarTitleDisplayMode(.inline)` でタイトルを常に中央固定
- 設定画面（`SettingsView`）は `ListsView` の `NavigationStack` 内に push 遷移。独自の `NavigationStack` を持たない
- `WidgetThemeListView` は `SettingsView` からの push 遷移先。独自の `NavigationStack` を持たない
- サウンドは `AVAudioEngine` + `AVAudioPlayerNode` で波形を生成して再生（`AVAudioSession` カテゴリ `.ambient` でメディアボリューム連動）。ハプティクスは `.sensoryFeedback(.success)` を使用。どちらも Todo 完了時のみ発火
- サウンドの種類は `CompletionSound` enum（`SettingsView.swift`）で管理。設定画面の「Sound Effect」から選択・プレビュー可能
- 設定値は `@AppStorage`（`soundEnabled`・`hapticEnabled`・`selectedSound`）で永続化
- `TodoList.swift`・`Todo.swift`・`WidgetTheme.swift` はメインアプリ（`todo-list`）・ウィジェット（`TodoListWidgetExtension`）両ターゲットに含める
- ウィジェットテーマは `WidgetTheme`（`Codable & Sendable`）として App Group の UserDefaults（キー: `widgetThemes`）に JSON 保存
- テーマの色は `ColorComponents`（RGBA）で保存。`nil` の場合はシステムカラー（自動）を使用
- チェックボックスのデザインは `WidgetCheckboxStyleValue` enum（10種類）で管理し、テーマに含めて保存
- ウィジェットは `@Environment(\.widgetRenderingMode)` で `.accented` モードを検出し、iOS 26 Liquid Glass に対応
- ウィジェットプレビュー用ビュー（`WidgetPreviewViews.swift`）は WidgetKit 専用 API を使わず、メインアプリのみのターゲットに含める
- `Todo` モデルは `dueDate: Date?`・`notificationID: String`・`repeatInterval: RepeatInterval?`・`repeatIntervalCount: Int`・`repeatWeekdays: [Int]`・`missedCount: Int`・`repeatEndCondition: RepeatEndCondition?`・`repeatEndCount: Int`・`repeatEndDate: Date?`・`repeatOccurrenceCount: Int` を持つ。SwiftData は optional / デフォルト値付きプロパティのライトウェイトマイグレーションを自動処理する
- `RepeatInterval` enum（`Todo.swift` に定義）は `String, Codable, CaseIterable`。`calendarComponent` プロパティで Calendar.Component に変換。`unitLabel(count:)` で単数/複数形のラベルを返す
- `RepeatEndCondition` enum（`Todo.swift` に定義）は `String, Codable`。`.afterCount`（N回繰り返し後に終了）と `.onDate`（特定日以降の次サイクルを停止）の2ケース。終了条件到達時は `todo_listApp.swift` の `stopRepeating` で `repeatInterval` をクリアして非繰り返しTodoに変換する
- `repeatWeekdays` は Calendar の weekday 番号（1=日〜7=土）の配列。Weekly かつ非空の場合に曜日指定繰り返しとして扱う
- `nextWeekdayOccurrence(after:weekdays:time:)` は `Todo.swift` に定義された自由関数。指定曜日リストの次回最近日時を返す
- 通知は `NotificationManager`（`@MainActor` シングルトン）が一元管理。`UNUserNotificationCenterDelegate` を実装してフォアグラウンド時もバナー表示。通知の `userInfo` に `notificationID`・`listTitle` を埋め込み。「Mark Complete」アクション（カテゴリ `TODO_DUE`）で通知から直接完了。曜日指定繰り返しの場合は曜日ごとに `"\(notificationID)_\(weekday)"` の個別IDでスケジュール
- 繰り返しTodoの自動前進ロジックは `todo_listApp.swift` の `advanceOverdueRepeatingTodos(in:)` 関数で実装。曜日指定の場合は `nextWeekdayOccurrence` で次回日時を計算、それ以外は `repeatIntervalCount` 単位で前進
- `WeekdaySelectorView` は曜日選択 UI コンポーネント。各曜日を `.glassEffect(in: Circle())` で Liquid Glass スタイルで表示。選択時は `.regular.tint(.blue)` で青いガラス。`DragGesture` でプレス状態を管理し、プレス中は `scaleEffect(1.18)` + `spring(bounce: 0.6)` でバウンス
- `AddTodoView`・`EditTodoView` のシート高さはともに内部の `selectedDetent` で動的に切り替え（340pt / 600pt / 700pt）。期日なし=340、期日あり=600、繰り返し+終了条件値あり=700

## シートUI共通仕様

- `presentationDetents([.height(280)])` で固定高さ
- `presentationCornerRadius(20)` で角丸
- Add/Saveボタン：青のフルボタン（未入力時は `Color.primary.opacity(0.06)` 背景 + secondary テキストで控えめに非活性表示）
- Cancelボタン：セカンダリカラーのテキストボタン
