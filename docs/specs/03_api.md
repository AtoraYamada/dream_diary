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

**リクエスト**:
```json
{
  "user": {
    "email": "user@example.com",
    "password": "password123"
  }
}
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
  "error": "Invalid email or password."
}
```

**実装**:
```ruby
# app/controllers/users/sessions_controller.rb
class Users::SessionsController < Devise::SessionsController
  respond_to :json

  private

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

**実装**:
```ruby
# app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  private

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
      }, status: :unprocessable_entity
    end
  end
end
```

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
| `0` | peace | 安らぎ・平穏 |
| `1` | chaos | 混沌 |
| `2` | fear | 恐怖 |
| `3` | exalt | 高揚 |

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

**実装**:
```ruby
# app/controllers/api/v1/dreams_controller.rb
class Api::V1::DreamsController < ApplicationController
  before_action :authenticate_user!

  def index
    @dreams = current_user.dreams
                          .includes(:tags)
                          .recent
                          .page(params[:page])
                          .per(params[:per_page] || 12)

    render json: {
      dreams: @dreams.map { |dream| dream_summary(dream) },
      pagination: pagination_meta(@dreams)
    }
  end

  private

  def dream_summary(dream)
    {
      id: dream.id,
      title: dream.title,
      emotion_color: dream.emotion_color,
      dreamed_at: dream.dreamed_at,
      tags: dream.tags.map { |tag| { id: tag.id, name: tag.name, category: tag.category } }
    }
  end

  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
      per_page: collection.limit_value
    }
  end
end
```

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

**実装**:
```ruby
def show
  @dream = current_user.dreams.includes(:tags).find(params[:id])
  render json: dream_detail(@dream)
end

private

def dream_detail(dream)
  {
    id: dream.id,
    title: dream.title,
    content: dream.content,
    emotion_color: dream.emotion_color,
    dreamed_at: dream.dreamed_at,
    tags: dream.tags.map { |tag| { id: tag.id, name: tag.name, category: tag.category } },
    created_at: dream.created_at,
    updated_at: dream.updated_at
  }
end
```

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

**実装**:
```ruby
def create
  @dream = current_user.dreams.build(dream_params)

  if @dream.save
    attach_tags(@dream, params[:dream][:tag_attributes])
    render json: dream_detail(@dream), status: :created
  else
    render json: { errors: @dream.errors.full_messages }, status: :unprocessable_entity
  end
end

private

def dream_params
  params.require(:dream).permit(:title, :content, :emotion_color, :dreamed_at)
end

def attach_tags(dream, tag_attrs)
  return if tag_attrs.blank?

  tag_attrs.each do |tag_attr|
    tag = current_user.tags.find_or_create_by(
      name: tag_attr[:name]
    ) do |t|
      t.yomi = tag_attr[:yomi]
      t.category = tag_attr[:category]
    end
    dream.tags << tag unless dream.tags.include?(tag)
  end
end
```

---

### 4. 更新

**エンドポイント**: `PUT /api/v1/dreams/:id`

**リクエスト**: 新規作成と同様

**レスポンス（200 OK）**: 新規作成と同様

**実装**:
```ruby
def update
  @dream = current_user.dreams.find(params[:id])

  if @dream.update(dream_params)
    # タグを更新
    @dream.tags.clear
    attach_tags(@dream, params[:dream][:tag_attributes])
    render json: dream_detail(@dream)
  else
    render json: { errors: @dream.errors.full_messages }, status: :unprocessable_entity
  end
end
```

---

### 5. 削除

**エンドポイント**: `DELETE /api/v1/dreams/:id`

**レスポンス（204 No Content）**: 空レスポンス

**実装**:
```ruby
def destroy
  @dream = current_user.dreams.find(params[:id])
  @dream.destroy
  head :no_content
end
```

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

**実装**:
```ruby
def search
  @dreams = current_user.dreams.includes(:tags)

  # キーワード検索（title + content）
  @dreams = @dreams.search_by_keyword(params[:keywords]) if params[:keywords].present?

  # タグ検索（AND条件）
  if params[:tag_ids].present?
    tag_ids = params[:tag_ids].split(',').map(&:to_i)
    @dreams = @dreams.tagged_with(tag_ids)
  end

  @dreams = @dreams.recent.page(params[:page]).per(12)

  render json: {
    dreams: @dreams.map { |dream| dream_summary(dream) },
    pagination: pagination_meta(@dreams)
  }
end
```

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

**実装**:
```ruby
def overflow
  dreams = current_user.dreams.order('RANDOM()').limit(10)
  fragments = []

  # 文章を句点で分割してランダムに5〜8文選択
  dreams.each do |dream|
    sentences = dream.content.split(/[。！？]/)
    fragments.concat(sentences.reject(&:blank?))
  end

  # データ不足時のフォールバック
  if fragments.size < 5
    fallback_fragments = [
      '遠くで鐘が鳴っている',
      '鍵は開いたままだ',
      '古びた本棚に埃が積もっている',
      '森の奥から誰かが呼んでいる',
      '月が二つ見える',
      '時計の針が逆回りしている',
      '窓の外に誰かの影が見える'
    ]
    fragments.concat(fallback_fragments)
  end

  selected = fragments.shuffle.take(rand(5..8))

  render json: { fragments: selected }
end
```

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
      "dream_count": 5
    },
    {
      "id": 2,
      "name": "古びた洋館",
      "yomi": "ふるびたようかん",
      "yomi_index": "ふ",
      "category": "place",
      "dream_count": 3
    }
  ]
}
```

**実装**:
```ruby
# app/controllers/api/v1/tags_controller.rb
class Api::V1::TagsController < ApplicationController
  before_action :authenticate_user!

  def index
    @tags = current_user.tags.includes(:dreams)

    @tags = @tags.by_category(params[:category]) if params[:category].present?
    @tags = @tags.by_yomi_index(params[:yomi_index]) if params[:yomi_index].present?

    render json: {
      tags: @tags.map { |tag| tag_summary(tag) }
    }
  end

  private

  def tag_summary(tag)
    {
      id: tag.id,
      name: tag.name,
      yomi: tag.yomi,
      yomi_index: tag.yomi_index,
      category: tag.category,
      dream_count: tag.dreams.count
    }
  end
end
```

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
    { "id": 1, "name": "太郎", "category": "person" },
    { "id": 5, "name": "太陽", "category": "place" }
  ]
}
```

**実装**:
```ruby
def suggest
  @tags = current_user.tags.search_by_name_or_yomi(params[:query])
  @tags = @tags.by_category(params[:category]) if params[:category].present?
  @tags = @tags.limit(10)

  render json: {
    suggestions: @tags.map { |tag| { id: tag.id, name: tag.name, category: tag.category } }
  }
end
```

---

### 3. タグ削除

**エンドポイント**: `DELETE /api/v1/tags/:id`

**レスポンス（204 No Content）**: 空レスポンス

**実装**:
```ruby
def destroy
  @tag = current_user.tags.find(params[:id])
  @tag.destroy
  head :no_content
end
```

---

## エラーレスポンス共通形式

**注記**: 以下のメッセージは `config/locales/ja.yml` で定義され、Rails i18n により日本語化されます。

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

すべての API リクエストは以下の構造でエラーハンドリングを実装してください：

```javascript
/**
 * API リクエスト（エラーハンドリング付き）
 */
async function apiRequest(url, options = {}) {
  const headers = {
    'Content-Type': 'application/json',
    'X-CSRF-Token': getCsrfToken(),
    ...options.headers
  };

  try {
    const response = await fetch(url, { ...options, headers });

    // ステータスコード別の処理
    if (!response.ok) {
      const errorData = await response.json();

      switch (response.status) {
        case 400:
          // バリデーションエラー
          console.error('入力エラー:', errorData.errors);
          showValidationError(errorData.errors);
          throw new Error(errorData.message || 'Invalid input');

        case 401:
          // 認証エラー（セッション切れ等）
          console.error('認証エラー');
          showAuthError('セッションが切れています。再度ログインしてください。');
          // ログイン画面へリダイレクト
          navigateWithBlink('auth.html');
          throw new Error('Unauthorized');

        case 404:
          // リソースが見つからない
          console.error('リソース未検出:', errorData.message);
          showError('データが見つかりません。');
          throw new Error('Not found');

        case 422:
          // 処理不可（バリデーションエラー）
          console.error('処理失敗:', errorData.errors);
          showValidationError(errorData.errors);
          throw new Error(errorData.message || 'Unprocessable entity');

        case 500:
          // サーバーエラー
          console.error('サーバーエラー');
          showError('サーバーエラーが発生しました。時間をおいて再度お試しください。');
          throw new Error('Internal server error');

        default:
          console.error(`エラー（${response.status}）:`, errorData);
          showError('予期しないエラーが発生しました。');
          throw new Error(`HTTP ${response.status}`);
      }
    }

    // 成功時のレスポンス処理
    return await response.json();

  } catch (error) {
    // ネットワークエラーや JSON パース エラー
    console.error('リクエスト失敗:', error);
    showError('通信に失敗しました。ネットワーク接続を確認してください。');
    throw error;
  }
}

/**
 * バリデーションエラー表示
 * @param {Object} errors - エラーオブジェクト { field: ['message1', 'message2'] }
 */
function showValidationError(errors) {
  const errorElement = document.getElementById('error-container');
  if (!errorElement) return;

  const errorMessages = Object.entries(errors)
    .map(([field, messages]) => `${field}: ${messages.join(', ')}`)
    .join('\n');

  errorElement.textContent = errorMessages;
  errorElement.classList.add('visible');

  setTimeout(() => {
    errorElement.classList.remove('visible');
  }, 5000);
}

/**
 * 認証エラー表示
 * @param {string} message - エラーメッセージ
 */
function showAuthError(message) {
  // 砂崩れアニメーション等で表示
  const errorElement = document.getElementById('auth-error');
  if (errorElement) {
    errorElement.textContent = message;
    errorElement.classList.add('sand-collapse');
    playSound('sfx_sand_crumble.wav');

    setTimeout(() => {
      errorElement.classList.remove('sand-collapse');
    }, 2000);
  }
}

/**
 * 汎用エラー表示
 * @param {string} message - エラーメッセージ
 */
function showError(message) {
  // トースト通知等で表示
  const errorElement = document.getElementById('error-toast');
  if (errorElement) {
    errorElement.textContent = message;
    errorElement.classList.add('visible');

    setTimeout(() => {
      errorElement.classList.remove('visible');
    }, 5000);
  }
}
```

### バックエンド（Rails）での対応

コントローラーでは必ず以下の構造でエラーレスポンスを返してください。**すべてのメッセージは `I18n.t()` を使用して ja.yml から取得します**：

```ruby
# app/controllers/api/v1/base_controller.rb
class Api::V1::BaseController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :render_404
  rescue_from ActiveRecord::RecordInvalid, with: :render_422

  private

  def render_400(errors)
    render json: {
      error: 'Bad Request',
      message: I18n.t('api.errors.bad_request'),
      errors: errors
    }, status: :bad_request
  end

  def render_401
    render json: {
      error: 'Unauthorized',
      message: I18n.t('api.errors.unauthorized')
    }, status: :unauthorized
  end

  def render_404
    render json: {
      error: 'Not Found',
      message: I18n.t('api.errors.not_found')
    }, status: :not_found
  end

  def render_422(exception)
    # バリデーションエラーをカスタマイズして日本語化
    errors = exception.record.errors.messages.transform_values do |messages|
      messages.map { |msg| translate_error_message(msg) }
    end

    render json: {
      error: 'Unprocessable Entity',
      errors: errors
    }, status: :unprocessable_entity
  end

  def render_500(exception)
    Rails.logger.error("Internal error: #{exception.message}")
    render json: {
      error: 'Internal Server Error',
      message: I18n.t('api.errors.internal_server_error')
    }, status: :internal_server_error
  end

  private

  def translate_error_message(msg)
    # バリデーションエラーメッセージを日本語化
    # 例: "can't be blank" => I18n.t('api.errors.blank')
    key_map = {
      "can't be blank" => 'api.errors.blank',
      "is too long" => 'api.errors.too_long',
      "is not included in the list" => 'api.errors.invalid_enum'
    }

    key = key_map.keys.find { |k| msg.include?(k) }
    key ? I18n.t(key_map[key]) : msg
  end
end
```

**対応する i18n 設定** (`config/locales/ja.yml`):
```yaml
ja:
  api:
    errors:
      # HTTPステータス別メッセージ
      bad_request: "リクエストが正しくありません"
      unauthorized: "ログインしてから続けてください"
      not_found: "見つかりません"
      internal_server_error: "エラーが発生しました。時間をおいて再度お試しください"

      # バリデーションエラーメッセージ
      blank: "が記入されていません"
      too_long: "が長すぎます"
      invalid_enum: "が無効です"
```

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
