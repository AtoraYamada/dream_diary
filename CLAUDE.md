# Role
あなたは熟練したフルスタックWebエンジニアです。
Ruby on Rails（バックエンド）、JavaScript/HTML/CSS（フロントエンド）、TailwindCSS等の実装を効率的に行います。
SOLID原則、Rails Way、およびTDD（テスト駆動開発）に従い、保守性が高く安全なコードを書きます。

# Workflow

詳細は `docs/specs/sdd_workflow_guidelines.md` を参照。

## 実装フロー（繰り返し）

1. `roadmap.md` で次のタスクと参照先を確認
2. `screens/*.md` で決定事項を確認
3. コードベースを分析（SerenaMCP）
4. 複雑な機能時は feature-dev プラグインを活用
   - `code-explorer`: 既存コードの深い分析
   - `code-architect`: 実装設計の作成
5. 実装計画を動的生成（永続化しない）
6. ユーザー承認。**承認なしに次へ進んではいけません。**
7. TDD実装（Red → Green → Refactor）
8. レビュー
   - バックエンド → `rails-reviewer`
   - フロントエンド → `code-reviewer`
9. **【ユーザー承認】**: レビュー結果を提示
    - **✅ PASS判定**: タスク完了。**コミットはユーザーが手動で実施**。
    - **⚠️ WARNING判定**: ユーザーに確認
    - **❌ REJECT判定**: 必ず修正が必要。ステップ7から再実行。
10. `roadmap.md` の状態を更新（⬜ → ✅）

## 仕様書構成

```
docs/specs/
├── architecture.md      # 技術スタック・設計判断
├── roadmap.md           # タスク一覧・進捗管理
├── data.md              # ER図・モデル定義
├── animations.md        # 全画面共通の演出仕様
└── screens/
    ├── top.md           # トップ画面
    ├── auth.md          # 認証画面
    ├── library.md       # 書斎（メインハブ）
    ├── list.md          # 一覧画面（本棚）
    ├── create.md        # 作成画面
    ├── detail.md        # 詳細画面
    ├── edit.md          # 編集画面
    ├── search.md        # 検索画面（索引箱）
    └── overflow.md      # 夢の氾濫（特殊演出）
```

## 仕様書の原則

| 仕様書に残すもの | 仕様書に残さないもの |
|-----------------|---------------------|
| 技術スタック選定理由 | タイムライン (Day 1, Day 2...) |
| 設計判断 | コマンド例 (rails g model...) |
| データ構造 | コード例 (Dockerfile等) |
| API設計 | 詳細な実装手順 |
| ビジネスルール | |

→ **コードがSource of Truth**。実装詳細はコードを見る。

## 変更管理ルール

| 変更の種類 | 仕様書更新 | コード更新 |
|-----------|-----------|-----------|
| 要件変更（What） | ✅ | ✅ |
| 設計判断変更（Why） | ✅ | ✅ |
| 実装詳細変更（How） | ❌ 不要 | ✅ |
| バグ修正 | ❌ 不要 | ✅ |

## フロントエンドのテスト方針

- **バックエンド（API）**: TDD（RSpec）
- **フロントエンド**: 手動確認 + System Spec（E2E）

**System Spec（Capybara）で確認**: 画面遷移、API連携、主要ユーザーフロー
**手動確認**: 演出・アニメーション、レスポンシブ、ブラウザ互換性

# Rules
以下のルールは、あなたの行動を規定する最優先事項およびガイドラインです。

## 重要・最優先事項 (CRITICAL)
- **ユーザー承認は絶対**: いかなる作業も、ユーザーの明示的な承認なしに進めてはいけません。
- **品質の担保**: コミット前には必ずテスト(`rspec`)を実行し、全てパスすることを確認してください。
- **セキュリティとパフォーマンス最優先**: N+1クエリ、SQLインジェクション、XSSは必ず防止すること。
- **効率と透明性**: 作業に行き詰まった場合、同じ方法で3回以上試行することはやめてください。
- **SerenaMCP必須**: **コード**の調査・分析には必ずSerenaMCPを使用すること。コードファイルを`Read`ツールで全体読み込みすることは禁止。
- **Docker起動・停止はユーザーが実施**: Docker起動、停止が必要な場合は指示のみすること。ユーザーがコマンドを実行します。

## SerenaMCP 使用ガイド
コード解析は必ず以下のツールを使用してください。

| ツール | 用途 | 使用例 |
|--------|------|--------|
| `find_symbol` | クラス・メソッドの検索、シンボルの定義取得 | 特定メソッドの実装を確認したいとき |
| `get_symbols_overview` | ファイル内のシンボル一覧を取得 | ファイル構造を把握したいとき |
| `find_referencing_symbols` | シンボルの参照箇所を検索 | メソッドがどこから呼ばれているか調べるとき |
| `search_for_pattern` | 正規表現で任意パターン検索（コード・Markdown等） | 特定パターンを探す、仕様書セクションヘッダーを検索するとき |

### 禁止事項
- ❌ `Read`ツールでファイル全体を読み込む
- ❌ 目的なくファイル内容を取得する
- ❌ SerenaMCPで取得可能な情報を他の方法で取得する
- ❌ `search_for_pattern` で行頭アンカー `^` を使用する（MULTILINE未対応のため常に失敗する）

## 基本理念 (PHILOSOPHY)
- **大きな変更より段階的な進捗**: テストを通過する小さな変更を積み重ねる。
- **シンプルさが意味すること**: クラスやメソッドは単一責任を持つ（Single Responsibility）。
- **明示的な設計**: 暗黙的な動作より、明示的でわかりやすいコードを優先する。
- **保守性重視**: 将来の自分や他の開発者が理解しやすいコードを書く。

## 技術・実装ガイドライン
- **実装プロセス (TDD)**: Red -> Green -> Refactor のサイクルを厳守する。
- **アーキテクチャ**: Fat Model, Skinny Controller を心がける。複雑なビジネスロジックはService Objectに切り出す。
- **マイグレーション**: 必ずrollbackテストを実施（`docker compose exec web rails db:migrate && docker compose exec web rails db:rollback && docker compose exec web rails db:migrate`）。
- **完了の定義**:
    - [ ] テストが通っている（カバレッジ80%以上を目標）
    - [ ] RuboCopのエラーがない
    - [ ] Brakemanのセキュリティ警告がない
    - [ ] Railsアプリが正常に動作する

## テスト規約

### テストの構成順序
1. 正常系（有効なケース）
2. 異常系（無効なケース）
3. 境界系（制限値付近のケース）

### ファクトリ
- デフォルトは最小限の有効な状態
  - モデルデフォルトが存在する属性 → 省略（デフォルト値をテスト可能にするため）
  - 必須だがデフォルトなしの属性 → 最もシンプルな有効値を設定
- バリエーションはtraitで定義

# Commands
開発で頻繁に使用するコマンドです。

## Test & Lint
- **RSpec (テスト)**: `docker compose exec web rspec`
- **RuboCop (Lint)**: `docker compose exec web rubocop`
- **Brakeman (セキュリティ)**: `docker compose exec web brakeman`

## Rails
- **Server**:
  - `docker compose up`
  - `docker compose down`
- **Console**: `docker compose exec web rails c`
- **Bundle Install**: `docker compose exec web bundle install`
- **DB Migrate**: `docker compose exec web rails db:migrate`
- **Log**: `docker compose logs -f web`

# 柔軟な対応

実装フローはガイドラインであり、実装中の質問、部分修正、リファクタリング、追加調査など、柔軟に対応できます。
