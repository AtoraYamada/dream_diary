# Day 2 Task 5: API層TDD - Green Phase 変更点記録

## 📌 概要

このドキュメントは、API層実装（Green Phase）における以下を記録します：
1. 実装ガイドからの変更点
2. 設計判断の理由
3. 実装中に発見した調整点
4. 仕様書更新時の参照情報

**目的**: 実装完了後、このドキュメントを基に `docs/specs/03_api.md` を更新する。

---

## 🔄 実装前の設計判断（実装ガイドからの変更点）

### 1. BaseController の必要性

**判断**: `Api::V1::BaseController` を実装する

**理由**:
- ApplicationController は `ActionController::Base`（HTML用）
- API は `ActionController::API`（JSON専用、軽量）を継承すべき
- 認証（`authenticate_user!`）とエラーハンドリングを共通化

**実装方針**:
```ruby
class Api::V1::BaseController < ActionController::API
  include Api::ErrorHandling
  before_action :authenticate_user!
end
```

---

### 2. Jbuilder ビューの最小化

**判断**: update/destroy 用のビューは作成しない

**理由**:
- **update**: `create.json.jbuilder` を使い回す（同じレスポンス形式）
- **destroy**: `head :no_content` でビュー不要

**実装するJbuilderファイル**:
- Dreams: `index`, `show`, `create`, `search`, `overflow` + partials（2ファイル）
- Tags: `index`, `suggest` + partials（1ファイル）
- 共通: `_pagination.json.jbuilder`

**合計**: 5 + 2 + 2 + 1 + 1 = **11ファイル**

---

### 3. Service Object の最小化

**判断**: `Dreams::SearchService` を実装しない

**理由**:
- モデルの `search_by_keyword` と `tagged_with` スコープで十分
- 過剰な抽象化を避ける（YAGNI原則）
- Rails Way に従う

**実装する Service Object**:
- ✅ `Dreams::AttachTagsService` - タグ関連付けロジック（複雑）
- ✅ `Dreams::OverflowService` - フラグメント生成ロジック（複雑）
- ❌ `Dreams::SearchService` - 不要（スコープで対応）

---

### 4. エラーハンドリングのシンプル化

**判断**: Concern は 404/422 のみ対応

**理由**:
- 400（Bad Request）: 使用頻度が低い
- 500（Internal Server Error）: Rails デフォルトで十分
- 最もよく使う 404/422 に集中

**実装する Concern**:
```ruby
module Api::ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_content
  end

  # render_not_found, render_unprocessable_content のみ実装
end
```

---

### 5. CORS設定の省略

**判断**: rack-cors gem を導入しない

**理由**:
- フロントエンドとバックエンドは同一オリジン（同じRailsアプリ）
- `public/*.html` から `/api/v1/*` へのリクエストは CORS 制約なし
- 将来、別ドメインにフロントエンドを分離する場合のみ必要

---

### 6. I18n メッセージの世界観統一

**判断**: API エラーメッセージも世界観に合わせる

**既存の世界観**（`config/locales/ja.yml`）:
- 「夢の残滓」「覚醒の刻印」「記憶の鍵」「連絡の灯火」
- 「蔵書目録」「筆録者」「栞の銘」「夢との邂逅の刻」

**API エラーメッセージ提案**（仮）:
```yaml
api:
  errors:
    bad_request: "願いの形が定かではありません"
    unauthorized: "この先に進むには記憶の鍵が必要です"
    forbidden: "この扉は開かれていません"
    not_found: "探し求めるものは見つかりませんでした"
    internal_server_error: "蔵書庫に異変が生じています。少し時を置いてお試しください"
```

**実装時に調整**: ユーザーと相談しながら最終決定

---

## 📝 実装中の変更点・気づき

### Phase 1: 基盤構築

#### ルーティング設定
- **実装内容**: `config/routes.rb` に API v1 名前空間とリソースルーティングを追加
- **変更点**:
  - `namespace :api` → `namespace :v1` のネスト構造
  - Dreams API: `member` アクション（overflow, suggest）を `collection` に変更
  - Tags API: `only: [:index, :destroy]` + `suggest` アクション
- **理由**: RESTful設計に従い、リソース単位の操作と検索系を明確に分離

#### Api::V1::BaseController
- **実装内容**: `app/controllers/api/v1/base_controller.rb` 作成
- **変更点**:
  ```ruby
  class BaseController < ActionController::API
    include Api::ErrorHandling
    before_action :set_default_format
    before_action :authenticate_user!
  ```
- **追加機能**: `set_default_format` で強制的に JSON フォーマットを設定
- **理由**: API専用コントローラーとして `ActionController::API` を継承し、不要なミドルウェアを削減

#### Api::ErrorHandling Concern
- **実装内容**: `app/controllers/concerns/api/error_handling.rb` 作成
- **実装内容**:
  ```ruby
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_content
  ```
- **メソッド名変更**: `render_unprocessable_entity` → `render_unprocessable_content` (コードレビュー対応)
- **HTTPステータス**: `:unprocessable_content` 使用（Rails 7.2推奨）
- **I18n対応**: エラーメッセージを世界観に合わせて国際化

#### ServiceResult
- **実装内容**: `config/initializers/service_result.rb` 作成
- **設計パターン**: Result Object Pattern
- **API**:
  ```ruby
  ServiceResult.success(value)
  ServiceResult.failure(errors)
  result.success? / result.failure?
  result.value / result.errors
  ```
- **理由**: サービスクラスの成功/失敗を統一的に扱うため

#### I18n 設定
- **実装内容**: `config/locales/ja.yml` に API エラーメッセージ追加
- **世界観統一**:
  ```yaml
  api:
    errors:
      not_found: "お探しのものは、ここには無いようです"
  ```
- **変更点**: 当初の世界観案よりシンプルで分かりやすい表現を採用

---

### Phase 2: Dreams API

#### DreamsController
- **実装内容**: `app/controllers/api/v1/dreams_controller.rb` 作成（7エンドポイント）
- **主要な変更点**:
  1. **Strong Parameters**: `dream_params` と `tag_attributes_params` に分離
  2. **tag_attributes_params の検証強化**: 空配列 `[]` が `[""]` になる Rails の挙動に対応
  3. **search アクション**: `includes(:tags)` と `joins(:tags)` の競合を回避
     - タグ検索時: `joins` のみ（`tagged_with` スコープ使用）
     - キーワード検索時: `includes` でN+1回避
  4. **データベース移植性**: `order('RANDOM()')` → `order(Arel.sql('RANDOM()'))`

- **コードレビュー対応（メソッド複雑度改善）**:
  - `create` アクション: プライベートメソッドに分割
    - `build_and_save_dream`
    - `attach_tags_to_dream`
  - `update` アクション: プライベートメソッドに分割
    - `update_dream_tags` (UpdateTagsService使用)
  - `search` アクション: プライベートメソッドに分割
    - `build_search_base_query`
    - `apply_keyword_search`
    - `apply_pagination`
  - エラーハンドリング共通化:
    - `render_validation_error`
    - `render_service_error`

#### Dreams::AttachTagsService
- **実装内容**: `app/services/dreams/attach_tags_service.rb` 作成
- **責務**: タグの作成 + 夢への関連付け
- **実装パターン**:
  ```ruby
  def call
    return ServiceResult.success(@dream) if @tag_attributes.blank?
    attach_tags
    ServiceResult.success(@dream)
  rescue => e
    ServiceResult.failure(errors)
  end
  ```
- **find_or_create_by!**: 既存タグの再利用（name のユニーク制約に従う）

#### Dreams::UpdateTagsService
- **実装内容**: `app/services/dreams/update_tags_service.rb` 作成（コードレビュー対応で追加）
- **責務**: 既存タグのクリア + 新規タグの関連付け
- **理由**: `@dream.tags.clear` のビジネスロジックをコントローラーから分離
- **実装**:
  ```ruby
  def call
    @dream.tags.clear
    AttachTagsService.call(@dream, @tag_attributes)
  end
  ```

#### Dreams::OverflowService
- **実装内容**: `app/services/dreams/overflow_service.rb` 作成
- **責務**: 夢のフラグメント（文の断片）をランダム生成
- **実装パターン**:
  1. 夢の content を句点で分割
  2. 空白要素を除去（`compact_blank` 使用、コードレビュー対応）
  3. 20個をランダム選択
  4. 不足時はフォールバック定数を使用
- **定数化**: `FALLBACK_FRAGMENTS` でマジックナンバー排除

#### Jbuilder ビュー（Dreams）
- **実装ファイル**:
  - `app/views/api/v1/dreams/index.json.jbuilder`
  - `app/views/api/v1/dreams/show.json.jbuilder`
  - `app/views/api/v1/dreams/create.json.jbuilder`
  - `app/views/api/v1/dreams/search.json.jbuilder`
  - `app/views/api/v1/dreams/_dream_detail.json.jbuilder`
  - `app/views/api/v1/dreams/_dream_summary.json.jbuilder`
- **設計パターン**: Partial による再利用
  - `_dream_summary`: 一覧・検索で使用（最小限の情報）
  - `_dream_detail`: 詳細・作成・更新で使用（タグ情報含む）
- **pagination の locals 修正**: `locals: { collection: @dreams }` でパラメータ渡し

---

### Phase 3: Tags API

#### TagsController
- **実装内容**: `app/controllers/api/v1/tags_controller.rb` 作成（3エンドポイント）
- **エンドポイント**:
  1. `index`: ユーザーのタグ一覧（カテゴリー・あいうえお順ソート）
  2. `suggest`: 部分一致サジェスト（name/yomi で LIKE 検索）
  3. `destroy`: タグ削除（関連する夢との紐付けも自動削除）
- **セキュリティ**: `current_user.tags` でスコープ制限
- **テスト修正**: 他ユーザーのタグ削除時の期待値を 401 → 404 に修正（仕様に合わせる）

#### Jbuilder ビュー（Tags）
- **実装ファイル**:
  - `app/views/api/v1/tags/index.json.jbuilder`
  - `app/views/api/v1/tags/suggest.json.jbuilder`
  - `app/views/api/v1/tags/_tag_summary.json.jbuilder`
- **設計パターン**: 共通 partial で DRY 原則遵守

---

### Phase 4: 共通部品

#### Pagination partial
- **実装内容**: `app/views/api/v1/shared/_pagination.json.jbuilder` 作成
- **Kaminari メタデータ**: current_page, total_pages, total_count を返す
- **使用方法**: `json.partial! 'api/v1/shared/pagination', locals: { collection: @dreams }`

---

## 🔍 テスト実行結果

### RSpec 実行結果（最終）
```
206 examples, 0 failures
Line Coverage: 93.08% (242/260)
```

**内訳**:
- Models: 133/133 ✅
- Services: 17/17 ✅ (AttachTags, UpdateTags, Overflow)
- Controller Concerns: 2/2 ✅
- Dreams API: 34/34 ✅
- Tags API: 20/20 ✅

### 失敗したテストと修正内容

#### 1. 初期実装時の失敗（403 Forbidden）
- **原因**: Rails 7.2 の Host Authorization が開発・テスト環境でもリクエストをブロック
- **修正**: `config/application.rb` に `config.hosts.clear if Rails.env.local?` 追加

#### 2. Jbuilder エラー（204 No Content）
- **原因**: jbuilder gem が Gemfile に含まれていなかった
- **修正**: `gem 'jbuilder', '~> 2.12'` 追加、bundle install

#### 3. Pagination partial エラー（undefined variable）
- **原因**: `json.partial!` の引数渡しで `locals:` が抜けていた
- **修正**: `json.partial! 'pagination', locals: { collection: @dreams }` に変更

#### 4. タグ削除テスト（422 Error）
- **原因**: Rails が空配列 `[]` を `[""]` に変換、String に対して `permit` を呼び出しエラー
- **修正**: `tag_attributes_params` で `.reject { |tag| tag.blank? || tag.is_a?(String) }` を追加

#### 5. 検索テスト（500 Error）
- **原因**: `includes(:tags)` と `joins(:tags)` の競合（tagged_with スコープ内で joins 使用）
- **修正**: タグ検索時は `includes` を使わず、キーワード検索時のみ使用

#### 6. Tags API テスト（401 vs 404）
- **原因**: テストの期待値が `:unauthorized` だったが、実装は 404 を返す
- **修正**: テスト期待値を `:not_found` に変更（仕様に合わせる）

### コードレビュー指摘事項の修正

#### 1. HTTPステータスコード非推奨（17件 → 0件）
- **対応箇所**:
  - Controllers: `:unprocessable_entity` → `:unprocessable_content`
  - Concerns: `render_unprocessable_entity` → `render_unprocessable_content` (メソッド名も変更)
  - Tests: 全テストで `:unprocessable_content` に統一
  - Devise設定: `config.responder.error_status = :unprocessable_content`

#### 2. メソッド複雑度超過（AbcSize 3件 → 0件）
- **対応**: DreamsController の create/update/search をプライベートメソッドに分割
- **効果**: 可読性向上、テスタビリティ向上

#### 3. アーキテクチャ改善
- **対応**: UpdateTagsService 作成（`@dream.tags.clear` をコントローラーから分離）
- **テスト**: 3テストケース追加（既存タグ、空配列、新規タグ）

#### 4. その他RuboCop違反（4件 → 0件）
- BaseController: インクルード後に空行追加
- OverflowService: `reject(&:blank?)` → `compact_blank`
- application.rb: `Rails.env.test? || Rails.env.development?` → `Rails.env.local?`
- Arel.sql使用: `order('RANDOM()')` → `order(Arel.sql('RANDOM()'))`

#### 5. テストコード改善
- `allow_any_instance_of` → インスタンスダブリングに変更
- `described_class` が使用できない箇所に `rubocop:disable` コメント追加

### 最終品質指標

| 項目 | 結果 |
|------|------|
| RSpec | ✅ 206 examples, 0 failures |
| Coverage | ✅ 93.08% (目標80%超え) |
| RuboCop | ✅ 0 offenses |
| Brakeman | ✅ 0 security warnings |

---

## 📊 仕様書更新時の参照情報

### 更新対象ファイル
- `docs/specs/03_api.md`

### 実装ガイドからの主要な変更点
1. **HTTPステータスコード**: `:unprocessable_entity` → `:unprocessable_content` に統一
2. **UpdateTagsService 追加**: タグ更新処理を Service Object に委譲
3. **DreamsController リファクタリング**: メソッド複雑度削減のためプライベートメソッド抽出
4. **エラーハンドリング**: メソッド名を `render_unprocessable_content` に統一
5. **データベース移植性**: `Arel.sql` 使用で他DBへの移植性向上

### 仕様書で更新すべき箇所
1. **ErrorHandling Concern のメソッド名**:
   - Before: `render_unprocessable_entity`
   - After: `render_unprocessable_content`

2. **HTTPステータスコード**: 全ての `:unprocessable_entity` を `:unprocessable_content` に変更

3. **UpdateTagsService の追加**: Service Object の説明に追加
   ```ruby
   # タグ更新時は UpdateTagsService を使用
   Dreams::UpdateTagsService.call(@dream, tag_attributes)
   ```

4. **DreamsController の設計パターン**: プライベートメソッドによる責務分離の例を追加

### 削除すべきコード例
- 仕様書の詳細なコード例（メソッド全体）は削除
- アプローチ・設計パターンのみ記載

### 追加すべき設計ガイドライン
- BaseController の役割（ActionController::API 継承の理由）
- Service Object の判断基準（複雑さに応じて導入）
- Jbuilder partial の再利用パターン
- プライベートメソッド抽出によるメソッド複雑度管理

---

## 📌 メモ・その他

### ハマりポイント

1. **Rails 7.2 の Host Authorization**: デフォルトで厳格になり、開発・テスト環境でも影響
   - 解決: `config.hosts.clear if Rails.env.local?`

2. **Rails の Parameter Coercion**: 空配列 `[]` が `[""]` に変換される
   - 解決: Strong Parameters で `.is_a?(String)` チェック追加

3. **ActiveRecord の includes/joins 競合**: スコープ内で joins 使用時に includes が競合
   - 解決: 条件分岐で includes と joins を使い分け

4. **Jbuilder の locals 記法**: `json.partial!` で locals が必須
   - 解決: `locals: { collection: @dreams }` を明示

### ベストプラクティス

1. **Thin Controller**: ビジネスロジックは Service Object に、複雑な処理はプライベートメソッドに
2. **N+1クエリ対策**: `includes(:tags)` でイーガーロード、ただし joins との競合に注意
3. **Service Result Pattern**: 成功/失敗を統一的に扱う Result Object を活用
4. **Jbuilder Partial**: 再利用可能な partial でDRY原則を守る
5. **Strong Parameters**: 厳格なバリデーションで予期しない入力を防ぐ

---

**作成日**: 2025-12-26
**作成者**: Claude Sonnet 4.5
**タスク**: Day 2 Task 5 - API層TDD Green Phase
