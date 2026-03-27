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
├── todo_listApp.swift    # エントリポイント
├── TodoList.swift        # リストモデル（@Model）
├── Todo.swift            # TodoモデL（@Model、TodoListと親子関係）
├── ListsView.swift       # ホーム画面（リスト一覧）
├── ContentView.swift     # リスト詳細画面（Todo一覧・セクション分け）
├── AddListView.swift     # リスト追加シート
├── AddTodoView.swift     # Todo追加シート
└── RenameListView.swift  # リスト名変更シート
```

## 主な機能

- 複数のTodoリストを作成・管理（タイトル付き）
- リスト名の変更（一覧画面のスワイプ or 詳細画面のタイトルタップ）
- Todoの追加（シートUI）
- タップでチェックON/OFF（アニメーション付き）
- 「未完了」「完了」セクションへの自動振り分け
- スワイプで削除（リスト・Todo両対応）
- エンプティステート表示

## 設計方針

- SwiftDataで永続化。`TodoList` が `@Relationship(deleteRule: .cascade)` で `Todo` を管理
- リスト削除時にTodoも自動削除される
- システムカラーを使用してダーク/ライトモードに自動対応
- 不要な抽象化を避け、最小限のコードで実装する

## シートUI共通仕様

- `presentationDetents([.height(280)])` で固定高さ
- `presentationCornerRadius(20)` で角丸
- Add/Saveボタン：青のフルボタン（未入力時はグレーで非活性）
- Cancelボタン：セカンダリカラーのテキストボタン
