# Day 2 Task 4: API層TDD - 実装ガイド

## タスク概要

**タスク4: API層TDD - Red Phase (1-1.5時間)**

### 目的
Request Specs（リクエスト仕様テスト）を作成し、**失敗するテストを先に書く（Red Phase）**。

### スコープ
- Dreams API: index, show, create, update, destroy, search, overflow
- Tags API: index, suggest, destroy
- 認証テスト（401 Unauthorized）
- エラーハンドリング（404, 422）
- JSONレスポンス形式の検証

### 実装しないもの（Green Phase で実装）
- コントローラー
- ルーティング
- Jbuilder ファイル
- Service Object
- `ja.yml` のエラーメッセージ

---

## 設計判断

### 1. Jbuilder の導入

**決定**: Jbuilder を使用する

**理由**:
- レスポンス構造の再利用性（partial で `dream_summary`, `dream_detail`, `tag_summary` を共有）
- コントローラーが薄くなる（Fat Model, Skinny Controller）
- JSON 構造の変更が容易（ビューだけ修正すれば良い）
- Rails の慣習に沿っている

**ファイル構成**:
```
app/views/api/v1/
├── dreams/
│   ├── index.json.jbuilder
│   ├── show.json.jbuilder
│   ├── create.json.jbuilder
│   ├── search.json.jbuilder
│   ├── overflow.json.jbuilder
│   ├── _dream_summary.json.jbuilder  # partial
│   └── _dream_detail.json.jbuilder   # partial
├── tags/
│   ├── index.json.jbuilder
│   ├── suggest.json.jbuilder
│   └── _tag_summary.json.jbuilder    # partial
└── shared/
    └── _pagination.json.jbuilder      # partial
```

---

### 2. Service Object の導入

**決定**: 複雑なビジネスロジックを Service Object に分離する

**対象ロジック**:
- `Dreams::AttachTagsService` - タグの find_or_create + 関連付け
- `Dreams::SearchService` - keywords + tag_ids の AND 検索
- `Dreams::OverflowService` - フラグメント生成ロジック

**ファイル構成**:
```
app/services/
├── service_result.rb              # Result パターンの基底クラス
└── dreams/
    ├── attach_tags_service.rb
    ├── search_service.rb
    └── overflow_service.rb
```

**呼び出し例**:
```ruby
def create
  @dream = current_user.dreams.build(dream_params)

  if @dream.save
    result = Dreams::AttachTagsService.call(@dream, tag_attributes_params)

    if result.success?
      render :create, status: :created
    else
      render json: { errors: result.errors }, status: :unprocessable_entity
    end
  else
    render json: { errors: @dream.errors.full_messages }, status: :unprocessable_entity
  end
end
```

---

### 3. Result パターンの導入

**決定**: Service Object の実行結果を Result パターンで表現する

**実装**:
```ruby
# app/services/service_result.rb
class ServiceResult
  attr_reader :value, :errors

  def initialize(success:, value: nil, errors: [])
    @success = success
    @value = value
    @errors = errors
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  # 便利メソッド
  def self.success(value = nil)
    new(success: true, value: value)
  end

  def self.failure(errors)
    new(success: false, errors: Array(errors))
  end
end
```

**使用例**:
```ruby
module Dreams
  class AttachTagsService
    def self.call(dream, tag_attributes)
      return ServiceResult.success(dream) if tag_attributes.blank?

      # ビジネスロジック...

      ServiceResult.success(dream)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(e.record.errors.full_messages)
    rescue => e
      ServiceResult.failure("タグの関連付けに失敗しました: #{e.message}")
    end
  end
end
```

---

### 4. Concern でエラーハンドリングを共通化

**決定**: `Api::ErrorHandling` Concern を導入する

**実装**:
```ruby
# app/controllers/concerns/api/error_handling.rb
module Api::ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActionController::ParameterMissing, with: :render_bad_request
    rescue_from StandardError, with: :render_internal_server_error
  end

  private

  def render_not_found
    render json: {
      error: 'Not Found',
      message: I18n.t('api.errors.not_found')
    }, status: :not_found
  end

  def render_bad_request
    render json: {
      error: 'Bad Request',
      message: I18n.t('api.errors.bad_request')
    }, status: :bad_request
  end

  def render_internal_server_error(exception)
    Rails.logger.error("Internal error: #{exception.message}\n#{exception.backtrace.join("\n")}")
    render json: {
      error: 'Internal Server Error',
      message: I18n.t('api.errors.internal_server_error')
    }, status: :internal_server_error
  end
end
```

**BaseController での使用**:
```ruby
# app/controllers/api/v1/base_controller.rb
class Api::V1::BaseController < ApplicationController
  include Api::ErrorHandling
  before_action :authenticate_user!
end
```

**役割分担**:
- **Concern**: システムレベルのエラー（404, 401, 500）
- **Result パターン**: ビジネスロジックの成功/失敗（Service Object の戻り値）

---

## 仕様書からの変更点

### 1. `dream_count` の削除

**変更**: Tags API のレスポンスから `dream_count` を削除

**理由**: ユーザー指示により仕様から削除

**修正後のレスポンス**:
```json
{
  "tags": [
    {
      "id": 1,
      "name": "太郎",
      "yomi": "たろう",
      "yomi_index": "た",
      "category": "person"
    }
  ]
}
```

---

### 2. `tag_attributes` は optional

**変更**: Dream 作成時に `tag_attributes` がなくても作成可能

**理由**: タグなしで夢を記録できる仕様

**実装時の注意**:
- `tag_attributes` が `nil` または空配列の場合はスキップ
- タグありの場合は N+1 回避（`includes(:tags)`）を実装

---

### 3. ページネーションの役割分担

**Rails 側のページネーション**:
- 用途: 一覧取得 API で大量のデータを分割取得
- 実装: Kaminari gem を使用
- 例: 100件の夢を12件ずつ表示

**フロントエンド側のページネーション**:
- 用途: 1つの夢の content（本文）を複数ページに分割
- 実装: BookReader クラス（JavaScript）
- 例: 10,000文字の夢を500文字ずつ分割

→ **両方必要**（役割が異なる）

---

### 4. `emotion_color` の扱い

**モデル**: enum で定義（0: peace, 1: chaos, 2: fear, 3: elation）

**API レスポンス**: enum のキー名（文字列）で返すelation

**実装方針**:
- モデルは enum のまま
- API レスポンスでは enum のキー名（文字列）で返す
- Jbuilder で `json.emotion_color dream.emotion_color` とすれば自動的に文字列になる

---

### 5. Tags suggest API のレスポンスに `yomi` を追加

**変更**: `/api/v1/tags/suggest` のレスポンスに `yomi` フィールドを追加

**理由**: 既存タグを選択して Dream に関連付ける際、yomi 情報が必要（yomi を再変換すると情報が競合する可能性があるため）

**修正後のレスポンス**:
```json
{
  "suggestions": [
    { "id": 1, "name": "太郎", "yomi": "たろう", "category": "person" }
  ]
}
```

**仕様書との差分**: 仕様書では yomi は含まれていないが、実装では含める

---

### 6. `lucid_dream_flag` パラメータの追加

**変更**: Dream の作成・更新パラメータに `lucid_dream_flag` を追加

**理由**: 将来的に明晰夢フラグを選択式で設定できるようにするため

**パラメータ例**:
```ruby
def dream_params
  params.require(:dream).permit(
    :title,
    :content,
    :emotion_color,
    :dreamed_at,
    :lucid_dream_flag  # 追加
  )
end
```

**デフォルト値**: false（モデルで既に設定済み）

---

## ベストプラクティス

### 1. N+1 対策

**includes の使用**:
```ruby
def index
  @dreams = current_user.dreams
                        .includes(:tags)  # N+1 回避
                        .recent
                        .page(params[:page])
                        .per(params[:per_page] || 12)
end
```

**Bullet gem の導入**（推奨）:
```ruby
# Gemfile
group :development, :test do
  gem 'bullet'
end

# config/environments/development.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true
  Bullet.rails_logger = true
end
```

---

### 2. Strong Parameters の厳密化

```ruby
def dream_params
  params.require(:dream).permit(
    :title,
    :content,
    :emotion_color,
    :dreamed_at
  )
end

def tag_attributes_params
  return [] unless params.dig(:dream, :tag_attributes)

  params.require(:dream)
        .fetch(:tag_attributes, [])
        .map { |tag| tag.permit(:name, :yomi, :category) }
end
```

---

### 3. I18n メッセージのカスタマイズ

**必要な `ja.yml` の項目**:

```yaml
ja:
  api:
    errors:
      # HTTPステータス別メッセージ
      bad_request: "リクエストが正しくありません"
      unauthorized: "ログインしてから続けてください"
      forbidden: "この操作は許可されていません"
      not_found: "見つかりません"
      internal_server_error: "エラーが発生しました。時間をおいて再度お試しください"

      # バリデーションエラーメッセージ
      blank: "が記入されていません"
      too_long: "が長すぎます"
      invalid_enum: "が無効です"
      invalid_date: "が無効な日付です"

  # モデル属性名の日本語化（世界観に合わせる）
  activerecord:
    attributes:
      dream:
        title: "夢の輪郭"
        content: "夢の記録"
        emotion_color: "感情彩色"
        dreamed_at: "見た日時"
      tag:
        name: "名"
        yomi: "読み"
        category: "種別"

    # モデル固有のエラーメッセージ（世界観重視）
    errors:
      models:
        dream:
          attributes:
            title:
              blank: "夢の輪郭が定まっていません"
              too_long: "夢の輪郭が複雑すぎます（15文字まで）"
            content:
              too_long: "夢が長すぎて記録に収まりません（10,000文字まで）"
            emotion_color:
              inclusion: "感情彩色が認識できません"
        tag:
          attributes:
            name:
              blank: "名が記されていません"
              too_long: "名が長すぎます"
            yomi:
              blank: "読みが記されていません"
```

---

### 4. レスポンスの一貫性

**成功レスポンス**:
```json
{
  "dreams": [...],
  "pagination": {...}
}
```

**エラーレスポンス（単一）**:
```json
{
  "error": "Not Found",
  "message": "見つかりません"
}
```

**エラーレスポンス（複数・バリデーション）**:
```json
{
  "errors": [
    "夢の輪郭が定まっていません",
    "夢が長すぎて記録に収まりません"
  ]
}
```

---

## 実装チェックリスト

### Green Phase で実装するファイル

#### 1. ルーティング
- [ ] `config/routes.rb` - Dreams/Tags のルーティング設定

#### 2. コントローラー
- [ ] `app/controllers/api/v1/base_controller.rb` - 基底コントローラー
- [ ] `app/controllers/api/v1/dreams_controller.rb` - Dreams API
- [ ] `app/controllers/api/v1/tags_controller.rb` - Tags API
- [ ] `app/controllers/concerns/api/error_handling.rb` - エラーハンドリング Concern

#### 3. Jbuilder ビュー
- [ ] `app/views/api/v1/dreams/index.json.jbuilder`
- [ ] `app/views/api/v1/dreams/show.json.jbuilder`
- [ ] `app/views/api/v1/dreams/create.json.jbuilder`
- [ ] `app/views/api/v1/dreams/search.json.jbuilder`
- [ ] `app/views/api/v1/dreams/overflow.json.jbuilder`
- [ ] `app/views/api/v1/dreams/_dream_summary.json.jbuilder`
- [ ] `app/views/api/v1/dreams/_dream_detail.json.jbuilder`
- [ ] `app/views/api/v1/tags/index.json.jbuilder`
- [ ] `app/views/api/v1/tags/suggest.json.jbuilder`
- [ ] `app/views/api/v1/tags/_tag_summary.json.jbuilder`
- [ ] `app/views/api/v1/shared/_pagination.json.jbuilder`

#### 4. Service Object
- [ ] `app/services/service_result.rb`
- [ ] `app/services/dreams/attach_tags_service.rb`
- [ ] `app/services/dreams/search_service.rb`
- [ ] `app/services/dreams/overflow_service.rb`

#### 5. I18n
- [ ] `config/locales/ja.yml` - エラーメッセージ追加

#### 6. Gem（必要であれば）
- [ ] `Gemfile` - Bullet gem 追加（開発環境）

---

## 参照

### Green Phase 開始時に読み込む仕様書

- **タスク定義**: `docs/specs/00_task_reference.md` 208-225行目
- **ルーティング設定**: `docs/specs/03_api.md` 26-64行目
- **Dreams API**: `docs/specs/03_api.md` 265-626行目
- **Tags API**: `docs/specs/03_api.md` 630-748行目
- **エラーレスポンス**: `docs/specs/03_api.md` 752-1243行目

### その他参照
- **DB設計**: `docs/specs/02_database.md`
- **フロントエンド仕様**: `docs/specs/04_frontend.md`

---

## 注意事項

1. **Red Phase では実装しない**: コントローラー、ルーティング、Jbuilder などは Green Phase で実装
2. **テストは失敗する前提**: 実装がないため、すべてのテストが失敗することを確認
3. **Jbuilder は使用しない前提でテストを書く**: テストは JSON レスポンスの構造を検証するだけなので、内部実装（Jbuilder vs 手動 JSON）は関係ない
4. **Service Object は使用しない前提でテストを書く**: テストはコントローラーの振る舞い（API の入出力）を検証するので、内部実装は関係ない

---

このガイドは Green Phase で参照してください。Green Phase 開始時に上記の仕様書セクションを読み込んでから実装を開始してください。
