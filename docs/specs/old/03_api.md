# 03. API仕様

## エンドポイント一覧

| Method | Path | 説明 | 認証 | 使用画面 |
|--------|------|------|------|---------|
| **認証** | | | | |
| POST | `/users/sign_in` | ログイン | 不要 | auth.html |
| DELETE | `/users/sign_out` | ログアウト | 必要 | library.html |
| POST | `/users` | サインアップ | 不要 | auth.html |
| **夢日記** | | | | |
| GET | `/api/v1/dreams` | 一覧取得 | 必要 | list.html |
| GET | `/api/v1/dreams/:id` | 詳細取得 | 必要 | list.html（モーダル） |
| POST | `/api/v1/dreams` | 新規作成 | 必要 | library.html（モーダル） |
| PUT | `/api/v1/dreams/:id` | 更新 | 必要 | library.html（モーダル） |
| DELETE | `/api/v1/dreams/:id` | 削除 | 必要 | list.html（モーダル） |
| GET | `/api/v1/dreams/search` | 検索（AND） | 必要 | list.html |
| GET | `/api/v1/dreams/overflow` | 夢の氾濫用 | 必要 | library.html |
| **タグ** | | | | |
| GET | `/api/v1/tags` | タグ一覧 | 必要 | list.html（索引箱） |
| GET | `/api/v1/tags/suggest` | サジェスト | 必要 | library.html（モーダル） |
| DELETE | `/api/v1/tags/:id` | タグ削除 | 必要 | list.html（索引箱） |

---

## ルーティング設定

### config/routes.rb

```ruby
Rails.application.routes.draw do
  # Devise認証
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  # 静的ページ
  root 'pages#index'
  get 'auth', to: 'pages#auth'
  get 'library', to: 'pages#library'
  get 'list', to: 'pages#list'

  # JSON API
  namespace :api do
    namespace :v1 do
      resources :dreams do
        collection do
          get :search
          get :overflow
        end
      end

      resources :tags, only: [:index, :destroy] do
        collection do
          get :suggest
        end
      end
    end
  end
end
```

---

## 認証API

### 1. ログイン

**エンドポイント**: `POST /users/sign_in`

**認証方式**: email **または** username でログイン可能

**リクエスト**:
```json
{
  "user": {
    "login": "user@example.com",  // email または username
    "password": "password123"
  }
}
```

**リクエスト例**:
```json
// email でログイン
{ "user": { "login": "user@example.com", "password": "password123" } }

// username でログイン
{ "user": { "login": "user1", "password": "password123" } }
```

**レスポンス（成功: 200 OK）**:
```json
{
  "message": "Logged in successfully.",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "username": "user1"
  }
}
```

**レスポンス（失敗: 401 Unauthorized）**:
```json
{
  "error": "Invalid login or password."
}
```

**実装** (Day 3 Task 3 で実施):
```ruby
# app/controllers/users/sessions_controller.rb
class Users::SessionsController < Devise::SessionsController
  respond_to :json
  before_action :configure_sign_in_params, only: [:create]

  private

  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:login])
  end

  def respond_with(resource, _opts = {})
    render json: {
      message: 'Logged in successfully.',
      user: {
        id: resource.id,
        email: resource.email,
        username: resource.username
      }
    }, status: :ok
  end

  def respond_to_on_destroy
    head :no_content
  end
end
```

**User モデル** (Day 3 Task 3 で実施):
```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :username, presence: true, uniqueness: { case_sensitive: false }

  # email OR username でログイン可能にする
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      where(conditions).where(
        ["lower(email) = :value OR lower(username) = :value", { value: login.downcase }]
      ).first
    elsif conditions.has_key?(:email)
      where(conditions).first
    else
      where(username: conditions[:username]).first
    end
  end
end
```

**Devise 初期化設定** (Day 3 Task 3 で実施):
```ruby
# config/initializers/devise.rb
config.authentication_keys = [:login]  # email の代わりに login を使用
```

**注意**:
- Day 1 では email のみでログイン（Devise デフォルト）
- Day 3 で email OR username 対応に拡張

---

### 2. サインアップ

**エンドポイント**: `POST /users`

**リクエスト**:
```json
{
  "user": {
    "email": "newuser@example.com",
    "username": "newuser",
    "password": "password123",
    "password_confirmation": "password123"
  }
}
```

**レスポンス（成功: 201 Created）**:
```json
{
  "message": "Signed up successfully.",
  "user": {
    "id": 2,
    "email": "newuser@example.com",
    "username": "newuser"
  }
}
```

**レスポンス（失敗: 422 Unprocessable Entity）**:
```json
{
  "errors": {
    "email": ["has already been taken"],
    "password": ["is too short (minimum is 6 characters)"]
  }
}
```

**実装** (Day 3 Task 3 で実施):
```ruby
# app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json
  before_action :configure_sign_up_params, only: [:create]

  private

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
  end

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: {
        message: 'Signed up successfully.',
        user: {
          id: resource.id,
          email: resource.email,
          username: resource.username
        }
      }, status: :created
    else
      render json: {
        errors: resource.errors.messages
      }, status: :unprocessable_content
    end
  end
end
```

**Strong Parameters の必要性**:
- `username` は Devise のデフォルトフィールドではないため、`configure_sign_up_params` で明示的に許可する必要がある
- 許可しない場合、フロントエンドから送信された `username` が無視される

---

### 3. ログアウト

**エンドポイント**: `DELETE /users/sign_out`

**リクエスト**: なし（認証ヘッダーのみ）

**レスポンス（成功: 204 No Content）**: 空レスポンス

---

## Dreams API

### emotion_color の値

すべての Dream API レスポンスで emotion_color フィールドが含まれます。以下の値に対応：

| 値 | 対応 | 説明 |
|----|------|------|
| `0` | peace | 平穏 |
| `1` | chaos | 混沌 |
| `2` | fear | 恐怖 |
| `3` | elation | 高揚 |

フロントエンドは emotion_color の値に基づいて、対応する感情彩色の画像ファイルを動的に選択して表示します（詳細は `04_frontend.md` 参照）。

---

### 1. 一覧取得

**エンドポイント**: `GET /api/v1/dreams`

**パラメータ**:
| パラメータ | 型 | 必須 | 説明 |
|-----------|---|------|------|
| page | integer | No | ページ番号（デフォルト: 1） |
| per_page | integer | No | 1ページあたりの件数（デフォルト: 12） |

**レスポンス（200 OK）**:
```json
{
  "dreams": [
    {
      "id": 1,
      "title": "古びた洋館の夢",
      "emotion_color": "peace",
      "dreamed_at": "2025-12-22T10:00:00Z",
      "tags": [
        { "id": 1, "name": "太郎", "category": "person" },
        { "id": 2, "name": "古びた洋館", "category": "place" }
      ]
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 58,
    "per_page": 12
  }
}
```

**実装原則**:
- `current_user.dreams` から取得
- `includes(:tags)` でN+1対策
- `recent` スコープで降順ソート
- Kaminari で `page()`, `per()` によるページネーション
- Jbuilder または手動JSONで `dream_summary` + `pagination_meta` 形式のレスポンス構築

詳細実装: `implementation_notes/day2_task5_api_green_phase_changes.md`

---

### 2. 詳細取得

**エンドポイント**: `GET /api/v1/dreams/:id`

**レスポンス（200 OK）**:
```json
{
  "id": 1,
  "title": "古びた洋館の夢",
  "content": "夢の内容が記述されます。昔々、あるところに...",
  "emotion_color": "peace",
  "dreamed_at": "2025-12-22T10:00:00Z",
  "tags": [
    { "id": 1, "name": "太郎", "category": "person" },
    { "id": 2, "name": "古びた洋館", "category": "place" }
  ],
  "created_at": "2025-12-22T10:05:00Z",
  "updated_at": "2025-12-22T10:05:00Z"
}
```

**実装原則**:
- `current_user.dreams.find(params[:id])` で取得（404自動ハンドリング）
- `includes(:tags)` でN+1対策
- Jbuilder または手動JSONで `dream_detail` 形式のレスポンス構築

詳細実装: `implementation_notes/day2_task5_api_green_phase_changes.md`

---

### 3. 新規作成

**エンドポイント**: `POST /api/v1/dreams`

**リクエスト**:
```json
{
  "dream": {
    "title": "古びた洋館の夢",
    "content": "夢の内容...",
    "emotion_color": "peace",
    "dreamed_at": "2025-12-22T10:00:00Z",
    "tag_attributes": [
      { "name": "太郎", "yomi": "たろう", "category": "person" },
      { "name": "古びた洋館", "yomi": "ふるびたようかん", "category": "place" }
    ]
  }
}
```

**レスポンス（201 Created）**:
```json
{
  "id": 1,
  "title": "古びた洋館の夢",
  "content": "夢の内容...",
  "emotion_color": "peace",
  "dreamed_at": "2025-12-22T10:00:00Z",
  "tags": [
    { "id": 1, "name": "太郎", "category": "person" },
    { "id": 2, "name": "古びた洋館", "category": "place" }
  ],
  "created_at": "2025-12-22T10:05:00Z",
  "updated_at": "2025-12-22T10:05:00Z"
}
```

**実装原則**:
- `current_user.dreams.build(dream_params)` で作成
- トランザクション内で実行
- `tag_attributes` が存在する場合、`AttachTagsService` で関連付け
- 成功: 201 Created + `dream_detail` 形式
- 失敗: 422 Unprocessable Content + バリデーションエラー配列

詳細実装: `implementation_notes/day2_task5_api_green_phase_changes.md`

---

### 4. 更新

**エンドポイント**: `PUT /api/v1/dreams/:id`

**リクエスト**: 新規作成と同様

**レスポンス（200 OK）**: 新規作成と同様

**実装原則**:
- `current_user.dreams.find(params[:id])` で取得
- トランザクション内で `update!` 実行
- `UpdateTagsService` でタグを更新（既存タグclear + 新規タグattach）
- 成功: 200 OK + `dream_detail` 形式
- 失敗: 422 Unprocessable Content + バリデーションエラー配列

詳細実装: `implementation_notes/day2_task5_api_green_phase_changes.md`

---

### 5. 削除

**エンドポイント**: `DELETE /api/v1/dreams/:id`

**レスポンス（204 No Content）**: 空レスポンス

**実装原則**:
- `current_user.dreams.find(params[:id])` で取得
- `destroy` 実行
- 204 No Content 返却

詳細実装: `implementation_notes/day2_task5_api_green_phase_changes.md`

---

### 6. 検索（AND条件）

**エンドポイント**: `GET /api/v1/dreams/search`

**パラメータ**:
| パラメータ | 型 | 必須 | 説明 |
|-----------|---|------|------|
| keywords | string | No | キーワード（title + content 検索） |
| tag_ids | string | No | タグID（カンマ区切り、例: "1,2,3"） |
| page | integer | No | ページ番号 |

**レスポンス（200 OK）**:
```json
{
  "dreams": [
    {
      "id": 1,
      "title": "古びた洋館の夢",
      "emotion_color": "peace",
      "dreamed_at": "2025-12-22T10:00:00Z",
      "tags": [...]
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 2,
    "total_count": 18,
    "per_page": 12
  }
}
```

**実装原則**:
- キーワード検索: `search_by_keyword(keywords)` スコープ（title + content）
- タグ検索: `tagged_with(tag_ids)` スコープ（AND条件）
- `tag_ids` 使用時は `includes(:tags)` と `joins(:tags)` の競合に注意
- ページネーション適用
- `dream_summary` + `pagination_meta` 形式で返却

詳細実装: `implementation_notes/day2_task5_api_green_phase_changes.md`

---

### 7. 夢の氾濫

**エンドポイント**: `GET /api/v1/dreams/overflow`

**レスポンス（200 OK）**:
```json
{
  "fragments": [
    "遠くで鐘が鳴っている。",
    "鍵は開いたままだ。",
    "古びた本棚に埃が積もっている。",
    "森の奥から誰かが呼んでいる。",
    "月が二つ見える。"
  ]
}
```

**実装原則**:
- `OverflowService` にロジック委譲
- ランダムに10件の夢を取得
- 文章を句点で分割してフラグメント化
- データ不足時はフォールバック文章を使用
- 5〜8個のフラグメントをランダム選択
- DB移植性のため `Arel.sql('RANDOM()')` 使用（PostgreSQL/SQLiteで動作）

詳細実装: `implementation_notes/day2_task5_api_green_phase_changes.md`

---

## Tags API

### 1. タグ一覧

**エンドポイント**: `GET /api/v1/tags`

**パラメータ**:
| パラメータ | 型 | 必須 | 説明 |
|-----------|---|------|------|
| category | string | No | カテゴリフィルタ（"person" or "place"） |
| yomi_index | string | No | 五十音インデックス（"あ", "か", ...） |

**レスポンス（200 OK）**:
```json
{
  "tags": [
    {
      "id": 1,
      "name": "太郎",
      "yomi": "たろう",
      "yomi_index": "た",
      "category": "person",
    },
    {
      "id": 2,
      "name": "古びた洋館",
      "yomi": "ふるびたようかん",
      "yomi_index": "ふ",
      "category": "place",
    }
  ]
}
```

**実装原則**:
- `current_user.tags` から取得
- `by_category(category)` スコープでカテゴリフィルタ
- `by_yomi_index(yomi_index)` スコープで五十音フィルタ
- Jbuilder または手動JSONで `tag_summary` 形式のレスポンス構築

詳細実装: `implementation_notes/day2_task5_api_green_phase_changes.md`

---

### 2. タグサジェスト

**エンドポイント**: `GET /api/v1/tags/suggest`

**パラメータ**:
| パラメータ | 型 | 必須 | 説明 |
|-----------|---|------|------|
| query | string | Yes | 検索文字列（name or yomi） |
| category | string | No | カテゴリフィルタ |

**レスポンス（200 OK）**:
```json
{
  "suggestions": [
    { "id": 1, "name": "太郎", "yomi": "たろう", "category": "person" },
    { "id": 5, "name": "太陽", "yomi": "たろう", "category": "place" }
  ]
}
```

**実装原則**:
- `search_by_name_or_yomi(query)` スコープで部分一致検索
- `by_category(category)` スコープでカテゴリフィルタ（optional）
- `limit(10)` で件数制限
- Jbuilder または手動JSONで suggestions 配列を構築

詳細実装: `implementation_notes/day2_task5_api_green_phase_changes.md`

---

### 3. タグ削除

**エンドポイント**: `DELETE /api/v1/tags/:id`

**レスポンス（204 No Content）**: 空レスポンス

**実装原則**:
- `current_user.tags.find(params[:id])` で取得（404自動ハンドリング）
- `destroy` 実行
- 204 No Content 返却

詳細実装: `implementation_notes/day2_task5_api_green_phase_changes.md`

---

## エラーレスポンス共通形式

**注記**: 以下のメッセージは例です。実際は `config/locales/ja.yml` で定義され、Rails i18n により日本語化されます。

### 400 Bad Request
```json
{
  "error": "Bad request",
  "message": "リクエストが正しくありません"
}
```

### 401 Unauthorized
```json
{
  "error": "Unauthorized",
  "message": "ログインしてから続けてください"
}
```

### 404 Not Found
```json
{
  "error": "Not found",
  "message": "見つかりません"
}
```

### 422 Unprocessable Entity
```json
{
  "errors": [
    "title: 夢の輪郭が定まっていません",
    "content: 夢が長すぎて記録に収まりません"
  ]
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error",
  "message": "エラーが発生しました。時間をおいて再度お試しください"
}
```

---

## エラーハンドリング実装ガイドライン

### フロントエンド（JavaScript）での対応

**実装原則**:
- `apiRequest(url, options)` 共通関数でエラーハンドリングを集約
- CSRF トークンをヘッダーに含める（`X-CSRF-Token`）
- ステータスコード別に switch 文で分岐
  - 400/422: `showValidationError()` でバリデーションエラー表示
  - 401: `showAuthError()` で認証エラー表示 + auth.html へリダイレクト
  - 404: `showError()` でリソース未検出を通知
  - 500: `showError()` でサーバーエラーを通知
- ネットワークエラーは try-catch で捕捉
- エラー表示は5秒後に自動消去

### バックエンド（Rails）での対応

**実装原則**:
- `Api::V1::BaseController` で `rescue_from` を使用してエラーハンドリングを集約
- または `Api::ErrorHandling` Concern に切り出して include
- 各エラーに対応する render メソッド（render_404, render_422 等）を実装
- すべてのメッセージは `I18n.t()` を使用して `config/locales/ja.yml` から取得
- バリデーションエラー（422）は `exception.record.errors.full_messages` を使用
- サーバーエラー（500）は Rails.logger でログ出力

**必要な i18n キー** (`config/locales/ja.yml`):
- `api.errors.not_found` (404 Not Found メッセージ用)

**注**: 実装時に `bad_request` (400), `unauthorized` (401), `internal_server_error` (500) のエラーハンドリングも議論したが、現在の実装では必要最小限の `not_found` のみ実装。バリデーションエラー（422）は `errors.full_messages` を使用。その他のエラーは必要に応じて将来追加可能。

詳細実装: `implementation_notes/day2_task5_api_green_phase_changes.md`

### 実装時の注意点

| 項目 | 対応 |
|------|------|
| **バリデーションエラー** | 400 or 422 で詳細エラー情報（フィールド名 + メッセージ）を返す |
| **認証エラー** | 401 を返す。フロント側で再度ログインさせる |
| **資源不在** | 404 を返す。フロント側でユーザーに通知 |
| **サーバーエラー** | 500 を返す。ログに詳細を記録。フロント側で再試行を促す |
| **ネットワークエラー** | try-catch で捕捉し、ユーザーに通知（通信失敗） |

---

## エンドポイント別エラーレスポンス詳細

実装時のリファレンスとして、各エンドポイントが返すエラーレスポンスの詳細例を示します。メッセージは `config/locales/ja.yml` で定義されます。

### Dreams API

#### POST /api/v1/dreams（新規作成）

**ステータスコード 422 - バリデーションエラー**:
```json
{
  "error": "Unprocessable Entity",
  "errors": {
    "title": "が記入されていません",
    "content": "が長すぎます（最大10,000文字）",
    "emotion": "が無効です"
  }
}
```

**考えられるバリデーション**:
- `title`: 空文字列、または15文字超過
- `content`: 10,000文字超過
- `emotion`: 0-3以外の値
- `date`: 無効な日付形式

**ステータスコード 401 - 認証エラー**:
```json
{
  "error": "Unauthorized",
  "message": "ログインしてから続けてください"
}
```

#### GET /api/v1/dreams（一覧取得）

**ステータスコード 401 - 認証エラー**:
```json
{
  "error": "Unauthorized",
  "message": "ログインしてから続けてください"
}
```

**ステータスコード 400 - パラメータエラー**:
```json
{
  "error": "Bad request",
  "message": "リクエストが正しくありません",
  "errors": ["page/limit パラメータが無効です"]
}
```

#### GET /api/v1/dreams/:id（詳細取得）

**ステータスコード 404 - リソース未検出**:
```json
{
  "error": "Not found",
  "message": "見つかりません"
}
```

**ステータスコード 401 - 認証エラー**:
```json
{
  "error": "Unauthorized",
  "message": "ログインしてから続けてください"
}
```

#### PUT /api/v1/dreams/:id（更新）

**ステータスコード 422 - バリデーションエラー**:
```json
{
  "error": "Unprocessable Entity",
  "errors": {
    "title": "が記入されていません",
    "content": "が長すぎます（最大10,000文字）"
  }
}
```

**ステータスコード 404 - リソース未検出**:
```json
{
  "error": "Not found",
  "message": "見つかりません"
}
```

**ステータスコード 401 - 認証エラー**:
```json
{
  "error": "Unauthorized",
  "message": "ログインしてから続けてください"
}
```

#### DELETE /api/v1/dreams/:id（削除）

**ステータスコード 404 - リソース未検出**:
```json
{
  "error": "Not found",
  "message": "見つかりません"
}
```

**ステータスコード 401 - 認証エラー**:
```json
{
  "error": "Unauthorized",
  "message": "ログインしてから続けてください"
}
```

#### GET /api/v1/dreams/search（検索）

**ステータスコード 400 - 検索パラメータエラー**:
```json
{
  "error": "Bad request",
  "message": "リクエストが正しくありません",
  "errors": ["keyword/emotion/tag のいずれか1つ以上が必須です"]
}
```

**ステータスコード 401 - 認証エラー**:
```json
{
  "error": "Unauthorized",
  "message": "ログインしてから続けてください"
}
```

#### GET /api/v1/dreams/overflow（夢の氾濫用）

**ステータスコード 401 - 認証エラー**:
```json
{
  "error": "Unauthorized",
  "message": "ログインしてから続けてください"
}
```

### Tags API

#### GET /api/v1/tags（タグ一覧取得）

**ステータスコード 401 - 認証エラー**:
```json
{
  "error": "Unauthorized",
  "message": "ログインしてから続けてください"
}
```

#### GET /api/v1/tags/suggest（タグサジェスト）

**ステータスコード 401 - 認証エラー**:
```json
{
  "error": "Unauthorized",
  "message": "ログインしてから続けてください"
}
```

**ステータスコード 400 - クエリパラメータエラー**:
```json
{
  "error": "Bad request",
  "message": "リクエストが正しくありません",
  "errors": ["パラメータ 'q' が必須です"]
}
```

#### DELETE /api/v1/tags/:id（タグ削除）

**ステータスコード 404 - リソース未検出**:
```json
{
  "error": "Not found",
  "message": "見つかりません"
}
```

**ステータスコード 401 - 認証エラー**:
```json
{
  "error": "Unauthorized",
  "message": "ログインしてから続けてください"
}
```

### 共通エラーハンドリング

**ステータスコード 500 - サーバーエラー**（すべてのエンドポイント共通）:
```json
{
  "error": "Internal Server Error",
  "message": "エラーが発生しました。時間をおいて再度お試しください"
}
```

**ステータスコード 503 - サービス利用不可**:
```json
{
  "error": "Service Unavailable",
  "message": "サーバーが一時的に利用できません。時間をおいて再度お試しください"
}
```

---

## CSRF トークン対応

### フロントエンド（JavaScript）

```javascript
// CSRF トークンを取得
const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

// fetch API でリクエスト
fetch('/api/v1/dreams', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': csrfToken
  },
  body: JSON.stringify({ dream: { ... } })
});
```

### バックエンド（Rails）

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, if: :json_request?

  private

  def json_request?
    request.format.json?
  end
end
```

---

このファイルは、API実装の完全ガイドです。
Day 2（API実装）、Day 3-4（フロントエンド統合）で参照してください。
