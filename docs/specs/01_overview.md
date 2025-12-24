# 01. 全体構成・アーキテクチャ

## プロジェクト概要

- **プロジェクト名**: 夢日記帳 (Dream Library)
- **開発期間**: 5日間（デプロイ除く）
- **技術スタック**: Rails 7 + PostgreSQL 15 + Docker + Vanilla JS
- **既存資産**: UIプロトタイプ完成済み（480行CSS + 406行JS + 4つのHTMLページ）

---

## アーキテクチャ

### 全体構成図

```
┌─────────────────────────────────────────────────────────┐
│                      Browser                            │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Static HTML (app/views/pages/)                   │  │
│  │  - index.html.erb (トップ)                         │  │
│  │  - auth.html.erb (認証)                            │  │
│  │  │  - library.html.erb (書斎)                       │  │
│  │  - list.html.erb (一覧)                            │  │
│  └───────────────────────────────────────────────────┘  │
│                          ↓                              │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Vanilla JavaScript (app/javascript/)             │  │
│  │  - common.js (共通処理・瞬き演出)                  │  │
│  │  - auth.js (認証処理)                              │  │
│  │  - scratchpad.js (LocalStorage連携)                │  │
│  │  - dream_editor.js (作成・編集)                    │  │
│  │  - dream_list.js (一覧表示)                        │  │
│  │  - dream_detail.js (詳細表示・削除)                │  │
│  │  - tag_suggest.js (タグサジェスト)                 │  │
│  │  - index_box.js (検索)                             │  │
│  └───────────────────────────────────────────────────┘  │
│                          ↓ Fetch API                   │
│  ┌───────────────────────────────────────────────────┐  │
│  │  JSON API (/api/v1/*)                             │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                  Rails 7 (Backend)                      │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Controllers (app/controllers/api/v1/)            │  │
│  │  - dreams_controller.rb                            │  │
│  │  - tags_controller.rb                              │  │
│  │  - users/sessions_controller.rb (Devise)          │  │
│  │  - users/registrations_controller.rb (Devise)     │  │
│  └───────────────────────────────────────────────────┘  │
│                          ↓                              │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Models (app/models/)                             │  │
│  │  - user.rb (Devise)                                │  │
│  │  - dream.rb                                        │  │
│  │  - tag.rb                                          │  │
│  │  - dream_tag.rb (中間テーブル)                     │  │
│  └───────────────────────────────────────────────────┘  │
│                          ↓                              │
│  ┌───────────────────────────────────────────────────┐  │
│  │  PostgreSQL 15 (Database)                         │  │
│  │  - users                                           │  │
│  │  - dreams                                          │  │
│  │  - tags                                            │  │
│  │  - dream_tags                                      │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### アーキテクチャの特徴

**フロントエンド**:
- 既存の Vanilla JS/HTML/CSS をそのまま使用
- 静的HTMLファイルを `app/views/pages/` に配置
- Rails は静的HTMLの配信のみ（テンプレートエンジン最小限）
- すべてのデータ操作は JSON API を通じて実行

**バックエンド**:
- Rails 7 を RESTful JSON API サーバーとして使用
- `/api/v1/*` エンドポイントで JSON レスポンス
- CORS 設定で フロントエンドからのリクエストを許可
- Devise も JSON レスポンス対応にカスタマイズ

---

## 技術スタック

| カテゴリ | 技術 | バージョン | 用途 |
|---------|------|-----------|------|
| **言語** | Ruby | 3.3 | サーバーサイド |
| | JavaScript | ES6+ | クライアントサイド |
| **フレームワーク** | Ruby on Rails | 7 | バックエンドAPI |
| **データベース** | PostgreSQL | 15 | メインDB |
| **認証** | Devise | 4.9+ | ユーザー認証 |
| **テスト** | RSpec | 3.12+ | テストフレームワーク |
| | FactoryBot | 6.2+ | テストデータ生成 |
| | SimpleCov | 0.22+ | カバレッジ測定 |
| **ページネーション** | Kaminari | 1.2+ | 一覧ページング |
| **CORS** | rack-cors | 2.0+ | クロスオリジン対応 |
| **コンテナ** | Docker | 20.10+ | 開発環境 |
| | Docker Compose | 1.29+ | コンテナ管理 |
| **読み仮名生成** | kuromoji.js | 0.1+ | 漢字→ひらがな変換 |

---

## Docker環境構成

### docker compose.yml

```yaml
version: '3.8'

services:
  db:
    image: postgres:15
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  web:
    build: .
    command: bash -c "rm -f tmp/pids/server.pid && bundle exec rails s -b '0.0.0.0'"
    volumes:
      - .:/app
      - bundle_data:/usr/local/bundle
    ports:
      - "3000:3000"
    depends_on:
      - db
    environment:
      DATABASE_URL: ${DATABASE_URL}
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}

volumes:
  postgres_data:
  bundle_data:
```

### Dockerfile

```dockerfile
FROM ruby:3.3

RUN apt-get update -qq && apt-get install -y nodejs npm postgresql-client

WORKDIR /app

# Gemfile/bundle installはvolume経由で管理（COPYしない）

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
```

### 環境変数設定（.env.sample）

```.env
# PostgreSQL設定
POSTGRES_USER=dream_diary_user
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=dream_diary_development

# Rails設定
DATABASE_URL=postgresql://dream_diary_user:your_secure_password@db:5432/dream_diary_development
SECRET_KEY_BASE=your_secret_key_base_here
RAILS_ENV=development

# テスト用DB
TEST_DATABASE_URL=postgresql://dream_diary_user:your_secure_password@db:5432/dream_diary_test
```

**セットアップ手順**:
```bash
# 1. 環境変数設定
cp .env.sample .env
# .env を編集（パスワード等を設定）

# 2. Docker起動
docker compose up -d

# 3. gem install
docker compose exec web bundle install

# 4. DB作成・マイグレーション
docker compose exec web rails db:create
docker compose exec web rails db:migrate
docker compose exec web rails db:seed

# 5. アセットコンパイル（本番環境の場合）
docker compose exec web rails assets:precompile
```

**gem永続化について**:
- `bundle_data` volumeを使用してgemを永続化
- Gemfile更新時も `docker compose exec web bundle install` のみで対応可能（`docker compose build`による再ビルド不要）

---

## デザインシステム

### フォント体系（世界観による区分）

Dream Diary では、**現実（トップページ）** と **夢の領域（扉を入った後）** を視覚的に区別するため、フォントを意識的に使い分けています。

#### 【現実】トップページ
- **フォント**: serif（明朝体）
- **意図**: 現実世界は素朴で古典的、紙のような温かみのある雰囲気
- **適用対象**:
  - `index.html.erb` のすべてのテキスト
  - 扉のテキスト、説明文、メモの入力エリア
  - ミュートボタンなど

#### 【夢の領域】扉を入った後（全ページ）
- **フォント**: `'DotGothic16'`, monospace（ビットマップフォント）
- **クラス**: `html.after-door` で制御
- **意図**: ピクセラートで幻想的、夢の領域であることを強調
- **適用対象**:
  - `auth.html.erb`（認証画面）
  - `library.html.erb`（書斎）
  - `list.html.erb`（一覧）
  - 詳細表示、モーダル、すべてのUI要素

### CSS変数定義（今後のCSS実装で使用）

```css
:root {
  /* フォント */
  --font-serif: serif;                    /* 現実（トップ） */
  --font-pixel: 'DotGothic16', monospace; /* 夢の領域 */

  /* 感情彩色（emotion_color） */
  --color-peace: #d4c5b9;   /* 0: 穏やか（ベージュ） */
  --color-chaos: #8b4c4c;   /* 1: 混沌（深紅） */
  --color-fear: #4a5568;    /* 2: 恐怖（紺） */
  --color-exalt: #c9a854;   /* 3: 歓喜（金） */
}

/* トップページ専用 */
html:not(.after-door) {
  font-family: var(--font-serif);
}

/* 扉を入った後（全ページ） */
html.after-door {
  font-family: var(--font-pixel);
}
```

### 世界観区分の実装方針

フロントエンド（Vanilla JS）では、ページ遷移時に HTML要素に **`after-door` クラス** を付与することで、扉を入った後の夢の領域を制御します：

**ページ別のクラス状態**:
- `index.html.erb`（トップページ）: `<html>` に `after-door` クラスなし → serif（明朝体）
- `auth.html.erb`（認証画面）: `<html class="after-door">` → DotGothic16
- `library.html.erb`（書斎）: `<html class="after-door">` → DotGothic16
- `list.html.erb`（一覧）: `<html class="after-door">` → DotGothic16

**ログアウト演出との関係**:
- ログアウト時に `awakening` クラスが付与される場合、`after-door` クラスは併せて削除される
- 目覚めの儀式の演出完了後、トップページに戻ると `after-door` クラスなしでserifが適用される

---

## Rails初期化

### rails new コマンド

```bash
docker compose run --rm web rails new . \
  --database=postgresql \
  --skip-test \
  --skip-bundle \
  --force
```

**オプション説明**:
- `--database=postgresql`: PostgreSQLを使用
- `--skip-test`: Minitest を除外（RSpecを使用）
- `--skip-bundle`: ローカルでの `bundle install` をスキップ（Docker環境で実行）
- `--force`: 既存ファイル（README.md、.gitignore）を上書き（非対話的実行のため必須）

---

## Gemfile構成

```ruby
source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.3.0'

# 基本
gem 'rails', '~> 7.2.3'
gem 'pg', '~> 1.5'
gem 'puma', '~> 6.0'

# Asset管理
gem 'sprockets-rails'
gem 'importmap-rails'

# 認証
gem 'devise', '~> 4.9'

# ページネーション
gem 'kaminari', '~> 1.2'

# CORS
gem 'rack-cors', '~> 2.0'

group :development, :test do
  gem 'rspec-rails', '~> 6.0'
  gem 'factory_bot_rails', '~> 6.2'
  gem 'faker', '~> 3.2'
  gem 'pry-rails'
  gem 'pry-byebug'
end

group :test do
  gem 'simplecov', '~> 0.22', require: false
  gem 'shoulda-matchers', '~> 5.3'
end

group :development do
  gem 'web-console'
  gem 'rubocop', '~> 1.50', require: false
  gem 'rubocop-rails', '~> 2.19', require: false
end
```

**インストール**:
```bash
docker compose exec web bundle install
```

---

## RuboCop設定

### .rubocop.yml

プロジェクトルートに以下の設定ファイルを作成します：

```yaml
AllCops:
  TargetRubyVersion: 3.3
  NewCops: enable
  Exclude:
    - 'db/**/*'
    - 'vendor/**/*'
    - 'node_modules/**/*'
    - 'bin/**/*'

Rails:
  Enabled: true

# メトリクス設定
Metrics/LineLength:
  Max: 120

Metrics/BlockLength:
  Exclude:
    - 'spec/**/*'
    - 'config/**/*'

Metrics/MethodLength:
  Max: 20
  Exclude:
    - 'spec/**/*'

# スタイル設定
Style/FrozenStringLiteralComment:
  Enabled: false

Style/StringLiterals:
  EnforcedStyle: double_quotes

Style/SymbolArray:
  EnforcedStyle: brackets

# Rails固有
Rails/Output:
  Enabled: false # console.logの代わりにputsを許可

Rails/FilePath:
  EnforcedStyle: arguments
```

### 使用方法

```bash
# 全ファイルをチェック
bundle exec rubocop

# 自動修正
bundle exec rubocop --auto-correct

# 特定のファイルのみチェック
bundle exec rubocop app/models/dream.rb

# ファイルを修正して終了
bundle exec rubocop --auto-correct-all
```

### CI統合（オプション）

テスト実行時にRubocopも実行する場合は、以下をスクリプトに追加：

```bash
# 両方を実行
bundle exec rubocop && bundle exec rspec
```

---

## Asset Pipeline設定

### config/initializers/assets.rb

```ruby
# バージョン設定
Rails.application.config.assets.version = '1.0'

# プリコンパイル対象
Rails.application.config.assets.precompile += %w(
  common.js
  auth.js
  scratchpad.js
  dream_editor.js
  dream_list.js
  dream_detail.js
  tag_suggest.js
  index_box.js
)

# 画像パス
Rails.application.config.assets.paths << Rails.root.join('app', 'assets', 'images')
```

### app/views/layouts/application.html.erb

```erb
<!DOCTYPE html>
<html>
  <head>
    <title>Dream Diary</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <%= stylesheet_link_tag "style", "data-turbo-track": "reload" %>
    <%= javascript_include_tag "common", "data-turbo-track": "reload", defer: true %>
  </head>

  <body>
    <%= yield %>
  </body>
</html>
```

---

## 感情彩色（emotion_color）の実装方針

感情彩色は以下の4色に対応します：
- `0`: peace（安らぎ・平穏）
- `1`: chaos（混沌）
- `2`: fear（恐怖）
- `3`: exalt（高揚）

### 対応アセット（各4色版で用意）

| アセット | ファイル名パターン |
|---------|-----------------|
| 本棚表示用の背表紙 | `img_book_spine_{peace\|chaos\|fear\|exalt}.png` |
| 本：正面（閉） | `img_book_closed_{peace\|chaos\|fear\|exalt}.png` |
| 本：半分開きかけ | `img_book_half_open_{peace\|chaos\|fear\|exalt}.png` |
| 本：見開きフレーム | `img_book_open_frame_{peace\|chaos\|fear\|exalt}.png` |
| インク瓶（作成UI用） | `img_ink_bottle_{peace\|chaos\|fear\|exalt}.png` |

### フロントエンド実装

emotion_color の値に応じて、対応する感情彩色の画像ファイルを動的に選択して表示します。詳細は `04_frontend.md § getEmotionImagePath 関数` を参照してください。

---

## テスト環境構成

### RSpec設定（spec/rails_helper.rb）

```ruby
require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'

  minimum_coverage 80
end

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # FactoryBot
  config.include FactoryBot::Syntax::Methods

  # Devise helpers
  config.include Devise::Test::IntegrationHelpers, type: :request
end
```

### FactoryBot設定（spec/support/factory_bot.rb）

```ruby
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.find_definitions
  end
end
```

### テスト実行コマンド

```bash
# 全テスト実行
docker compose exec web rspec

# カバレッジ確認
# coverage/index.html を開く

# 特定のファイルのみ実行
docker compose exec web rspec spec/models/dream_spec.rb

# 特定の行のテストのみ実行
docker compose exec web rspec spec/models/dream_spec.rb:15
```

### RuboCop設定（.rubocop.yml）

**Day 1 タスク4 で作成**:

```yaml
AllCops:
  TargetRubyVersion: 3.3
  NewCops: enable
  Exclude:
    - 'db/**/*'
    - 'vendor/**/*'
    - 'node_modules/**/*'
    - 'bin/**/*'

Rails:
  Enabled: true

# メトリクス設定
Metrics/LineLength:
  Max: 120

Metrics/BlockLength:
  Exclude:
    - 'spec/**/*'
    - 'config/**/*'

Metrics/MethodLength:
  Max: 20
  Exclude:
    - 'spec/**/*'

# スタイル設定
Style/FrozenStringLiteralComment:
  Enabled: false

Style/StringLiterals:
  EnforcedStyle: double_quotes

Style/SymbolArray:
  EnforcedStyle: brackets

# Rails固有
Rails/Output:
  Enabled: false

Rails/FilePath:
  EnforcedStyle: arguments
```

### RuboCop実行コマンド

```bash
# 全ファイルをチェック
docker compose exec web rubocop

# 自動修正
docker compose exec web rubocop --auto-correct

# 特定のファイルのみ
docker compose exec web rubocop app/models/dream.rb

# テスト + RuboCop を同時実行
docker compose exec web bash -c "rubocop && rspec"
```

### 品質チェック・ワークフロー（Day 2以降）

```bash
# Rails実装後、毎回実行するコマンド
docker compose exec web bash -c "rubocop && rspec"

# 自動修正が必要な場合
docker compose exec web rubocop --auto-correct-all
docker compose exec web rspec
```

---

## ファイル配置

### 静的ファイル移行マッピング

| プロトタイプ | Rails配置先 | 用途 |
|------------|-----------|------|
| `prototype/index.html` | `app/views/pages/index.html.erb` | トップページ |
| `prototype/auth.html` | `app/views/pages/auth.html.erb` | 認証画面 |
| `prototype/library.html` | `app/views/pages/library.html.erb` | 書斎（メイン） |
| `prototype/list.html` | `app/views/pages/list.html.erb` | 一覧画面 |
| `prototype/css/style.css` | `app/assets/stylesheets/style.css` | 共通CSS |
| `prototype/js/script.js` | `app/javascript/common.js` | 共通JS |
| `prototype/assets/*.png` | `app/assets/images/*` | 画像素材 |
| `prototype/assets/*.{wav,mp3}` | `app/assets/sounds/*` | 音声素材 |

### 画像パス変更

**プロトタイプ**:
```css
background-image: url('assets/bg_library_wall_up.png');
```

**Rails（ERBテンプレート内のCSS）**:
```erb
<style>
  background-image: url(<%= asset_path('bg_library_wall_up.png') %>);
</style>
```

**Rails（style.css内）**:
```css
background-image: asset-url('bg_library_wall_up.png');
```

---

## 開発環境セットアップ手順（まとめ）

### 初回セットアップ

```bash
# 1. リポジトリクローン
git clone <repository_url>
cd dream_diary

# 2. 環境変数設定
cp .env.sample .env
# .envを編集（パスワード等を設定）

# 3. Docker起動
docker compose up -d

# 4. 依存関係インストール
docker compose exec web bundle install

# 5. DB作成・マイグレーション
docker compose exec web rails db:create
docker compose exec web rails db:migrate
docker compose exec web rails db:seed

# 6. 動作確認
open http://localhost:3000
```

### 日々の開発

```bash
# サーバー起動
docker compose up

# サーバー停止
docker compose down

# テスト実行
docker compose exec web rspec

# コンソール起動
docker compose exec web rails c

# ログ確認
docker compose logs -f web
```

---

## CORS設定

### config/initializers/cors.rb

```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'localhost:3000', '127.0.0.1:3000'

    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end
```

**注意**: 本番環境では `origins` を適切なドメインに変更

---

## 重要な設計判断

1. **アーキテクチャ**: Rails API + 静的HTML配信（SPAではない）
2. **データベース**: PostgreSQL（Docker環境で推奨）
3. **認証**: Devise（JSON API対応にカスタマイズ）
4. **テスト**: RSpec + FactoryBot + SimpleCov（カバレッジ80%目標）
5. **読み仮名生成**: kuromoji.js（クライアントサイド、gem不要）
6. **実装優先順位**: CRUD → UI → 演出（機能優先、演出は最後）

---

このファイルは、プロジェクト全体の技術的基盤を定義しています。
実装時は、このファイルを参照して環境構築と基本設定を行ってください。
