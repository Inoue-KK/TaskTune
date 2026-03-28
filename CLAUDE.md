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
├── todo_listApp.swift    # エントリポイント（App Group対応・WidgetKit連携）
├── TodoList.swift        # リストモデル（@Model）
├── Todo.swift            # TodoモデL（@Model、TodoListと親子関係）
├── ListsView.swift       # ホーム画面（リスト一覧・ディープリンク対応）
├── ContentView.swift     # リスト詳細画面（Todo一覧・セクション分け）
├── AddListView.swift     # リスト追加シート
├── AddTodoView.swift     # Todo追加シート
└── RenameListView.swift  # リスト名変更シート

TodoListWidget/
├── TodoListWidgetBundle.swift  # ウィジェットのエントリポイント（@main）
└── TodoListWidget.swift        # ウィジェット実装（Small/Medium・インタラクティブ対応）
```

## 主な機能

- 複数のTodoリストを作成・管理（タイトル付き）
- リスト名の変更（一覧画面のスワイプ or 詳細画面のタイトルタップ）
- Todoの追加（シートUI）
- タップでチェックON/OFF（アニメーション付き）
- 「未完了」「完了」セクションへの自動振り分け
- スワイプで削除（リスト・Todo両対応）
- エンプティステート表示
- ホーム画面ウィジェット（Small/Medium）
  - 表示するリストをウィジェット設定で選択可能
  - Mediumウィジェット上で直接Todoを完了にできる（iOS 17 Interactive Widgets）
  - ウィジェットタップで該当リストを直接開く（ディープリンク）
  - アプリがバックグラウンドに移行したタイミングでウィジェットを自動更新

## 設計方針

- SwiftDataで永続化。`TodoList` が `@Relationship(deleteRule: .cascade)` で `Todo` を管理
- リスト削除時にTodoも自動削除される
- システムカラーを使用してダーク/ライトモードに自動対応
- 不要な抽象化を避け、最小限のコードで実装する
- App Group（`group.com.inoue-kk.todo-list`）経由でメインアプリとウィジェットがSwiftDataストアを共有
- ウィジェットとのディープリンクはURLスキーム `todolist://list/{リスト名}` を使用
- `ListsView` は `NavigationPath` でプログラマティックナビゲーションに対応
- `TodoList.swift` と `Todo.swift` はメインアプリ・ウィジェット両ターゲットに含める

## シートUI共通仕様

- `presentationDetents([.height(280)])` で固定高さ
- `presentationCornerRadius(20)` で角丸
- Add/Saveボタン：青のフルボタン（未入力時はグレーで非活性）
- Cancelボタン：セカンダリカラーのテキストボタン
