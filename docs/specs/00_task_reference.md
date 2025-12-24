# Dream Diary 実装タスク対応表

このファイルは、5日間実装プランの各タスクと、参照すべき仕様書の対応表です。
実装時は、このファイルで参照すべき仕様書を確認してから作業を開始してください。

**仕様書一覧**:
- `01_overview.md` - 全体構成・アーキテクチャ・技術スタック
- `02_database.md` - DB設計（テーブル、モデル、バリデーション）
- `03_api.md` - API仕様（エンドポイント、リクエスト/レスポンス）
- `04_frontend.md` - フロントエンド実装（ファイル構成、主要関数）
- `05_animations.md` - 演出仕様（瞬き、画面遷移、保存/削除演出）

---

## Day 1: Docker環境 + Rails基盤セットアップ

### タスク1: Docker環境構築 (2-3時間)

**参照仕様書**:
- `01_overview.md` § Docker環境構成

**実装内容**:
- `Dockerfile` 作成（Ruby 3.3 + Node.js + PostgreSQLクライアント）
  - gem永続化対応: Gemfile COPYとbundle installは削除（volume経由で管理）
- `docker compose.yml` 作成（db: PostgreSQL 15 / web: Rails + bundle_data volume）
- `.env.sample` 作成（環境変数テンプレート）
- 構文確認

**コマンド例**:
```bash
# docker compose.yml の構文確認
docker compose config
```

---

### タスク2: Rails初期化 (1-2時間)

**参照仕様書**:
- `01_overview.md` § Gemfile構成

**実装内容**:
1. **Railsプロジェクト生成**（Dockerコンテナ内で実行）:
   ```bash
   # 仮のGemfile作成
   echo "source 'https://rubygems.org'" > Gemfile
   echo "gem 'rails', '~> 7.2.3'" >> Gemfile

   # bundle install（一時的）
   docker compose run --rm web bundle install

   # Railsプロジェクト生成
   docker compose run --rm web bundle exec rails new . --database=postgresql --skip-test --skip-bundle --force
   ```
2. **Gemfile編集**（devise, rspec-rails, factory_bot_rails, simplecov, kaminari, rack-cors, bootsnap, rubocop, rubocop-rails）
3. **config/database.yml編集**（環境変数使用）:
   - defaultセクションに`host`, `username`, `password`を環境変数から読み込む設定を追加
   - 参照: `01_overview.md` § database.yml設定
4. **.envファイル作成 + SECRET_KEY_BASE生成**:
   ```bash
   cp .env.sample .env

   # SECRET_KEY_BASE生成
   docker compose exec web bundle exec rails secret
   # 生成された値を.envのSECRET_KEY_BASEに設定
   ```
5. **Docker再起動 + gem install + DB作成**:
   ```bash
   docker compose down
   docker compose up -d
   docker compose exec web bundle install
   docker compose exec web rails db:create
   docker compose exec web rails db:create RAILS_ENV=test
   ```

**注意点**:
- `--skip-test` で Minitest を除外（RSpecを使用）
- `--skip-bundle` でホストでのbundle installをスキップ（Docker環境で実行）
- `--force` で既存ファイル（README.md、.gitignore、**Dockerfile**）を上書き（非対話的実行のため必須）→ **Dockerfileは元に戻す必要あり**
- `bootsnap` を追加（起動時間短縮）
- `rack-cors` は後で CORS 設定に使用
- **`rubocop` と `rubocop-rails` を development グループに追加**（Day 1 Task 4 でセットアップ）
- gem永続化により、Gemfile更新時は `docker compose exec web bundle install` のみで対応可能（再ビルド不要）
- **database.ymlで環境変数を使用**するため、.envから`DATABASE_URL`は削除

---

### タスク3: Devise導入 (1-2時間)

**参照仕様書**:
- `02_database.md` § users テーブル（Devise生成）
- `02_database.md` § 実装ガイドライン
- `03_api.md` § 認証API


**実装内容**:
- `docker compose exec web rails generate devise:install`
- `docker compose exec web rails generate devise User`
- マイグレーションに `username:string` カラム追加（unique）
- `docker compose exec web rails db:migrate`
- Devise設定: JSON API対応（`config/initializers/devise.rb`）

---

### タスク4: RSpec + RuboCop + Brakeman + CI設定環境セットアップ (1.5-2時間)

**参照仕様書**:
- `01_overview.md` § テスト環境構成

**実装内容**:

**RSpec設定**:
- `docker compose exec web rails generate rspec:install`
- SimpleCov設定（`spec/spec_helper.rb`）
- サンプルテスト実行確認

**RuboCop設定**:
- 'rubocop-rspec'導入
- `.rubocop.yml` を作成（`01_overview.md` § RuboCop設定に従う）
- `docker compose exec web rubocop` で動作確認

**Brakeman + CI設定**:
- Gemfileに`brakeman`を追加（developmentグループ）
- `.github/workflows/ci.yml`を作成:
  - RSpecテスト実行
  - RuboCop lint
  - Brakemanセキュリティスキャン
- PR時に自動実行されることを確認

**品質チェックワークフロー確立**:
- Day 2 以降、各機能実装後に `docker compose exec web bash -c "brakeman && rubocop && rspec"` を実行する習慣をつける

**目標**:
- テストカバレッジ 80%以上
- RuboCop 違反 0件
- Brakemanのセキュリティ警告がない

---

## Day 2: データベース設計 + CRUD API実装

### タスク1: モデル生成 + マイグレーション (1-2時間)

**参照仕様書**:
- `02_database.md` § テーブル定義
- `02_database.md` § マイグレーションコマンドまとめ
- `02_database.md` § 実装ガイドライン

**実装内容**:
- Dream モデル生成
- Tag モデル生成
- DreamTag モデル生成（中間テーブル）
- `docker compose exec web rails db:migrate`

**生成コマンド**:
```bash
docker compose exec web rails g model Dream user:references title:string content:text emotion_color:integer lucid_dream_flag:boolean dreamed_at:datetime
docker compose exec web rails g model Tag user:references name:string yomi:string yomi_index:string category:integer
docker compose exec web rails g model DreamTag dream:references tag:references
```

---

### タスク2: モデル実装 (2-3時間)

**参照仕様書**:
- `02_database.md` § Dream モデル
- `02_database.md` § Tag モデル
- `02_database.md` § DreamTag モデル（中間テーブル）

**実装内容**:
- **Dream モデル**:
  - enum（emotion_color）
  - バリデーション（title: 15文字、content: 10,000文字）
  - 検索スコープ（title + content の LIKE 検索）
- **Tag モデル**:
  - enum（category, yomi_index）
  - バリデーション（name, yomi, yomi_index 必須）
  - before_validation コールバック（yomi_index 自動生成）
- **アソシエーション**:
  - `has_many :through` で Dream ↔ Tag の多対多関係

---

### タスク3: API実装 (3-4時間)

**参照仕様書**:
- `03_api.md` § ルーティング設定
- `03_api.md` § Dreams API
- `03_api.md` § Tags API

**実装内容**:
- `config/routes.rb` 編集（`namespace :api do`）
- `Api::V1::DreamsController` 実装
  - index, show, create, update, destroy, search, overflow
- `Api::V1::TagsController` 実装
  - index, suggest, destroy
- JSON レスポンス形式統一

**注意点**:
- CORS設定（`rack-cors` gem使用）
- 認証必須（Devise の `authenticate_user!`）

---

### タスク4: テスト実装 (1-2時間)

**参照仕様書**:
- `02_database.md` § テスト仕様

**実装内容**:
- Model specs（バリデーション、スコープ、enum）
- Request specs（CRUD + 検索エンドポイント）
- FactoryBot定義（Dream, Tag, User）

**目標**: テストカバレッジ 80%以上

---

## Day 3: UIプロトタイプ統合 + 認証フロー

### タスク1: 静的ファイル移行 (1-2時間)

**参照仕様書**:
- `01_overview.md` § ファイル配置
- `01_overview.md` § Asset Pipeline設定

**実装内容**:
```
prototype/index.html → app/views/pages/index.html.erb
prototype/auth.html → app/views/pages/auth.html.erb
prototype/library.html → app/views/pages/library.html.erb
prototype/list.html → app/views/pages/list.html.erb
prototype/css/style.css → app/assets/stylesheets/style.css
prototype/js/script.js → app/javascript/common.js
prototype/assets/*.png → app/assets/images/*
prototype/assets/*.{wav,mp3} → app/assets/sounds/*
```

---

### タスク2: Asset Pipeline設定 (1時間)

**参照仕様書**:
- `01_overview.md` § Asset Pipeline設定
- `01_overview.md` § 画像パス変更

**実装内容**:
- `config/initializers/assets.rb` 設定
- `app/views/layouts/application.html.erb` 作成
- 画像パス変更: `url('assets/...')` → `asset-path(...)`

---

### タスク3: Devise JSON API化 (2-3時間)

**参照仕様書**:
- `03_api.md` § 認証API
- `04_frontend.md` § 認証処理（auth.js）

**実装内容**:
- `Users::SessionsController` カスタマイズ（JSON レスポンス）
- `Users::RegistrationsController` カスタマイズ（JSON レスポンス）
- CSRF トークン対応
- 認証失敗時のエラーレスポンス（JSON形式）

**エンドポイント**:
- ログイン: `POST /users/sign_in`
- サインアップ: `POST /users`
- ログアウト: `DELETE /users/sign_out`

---

### タスク4: フロントエンド認証処理 (2-3時間)

**参照仕様書**:
- `04_frontend.md` § デザインシステム（フォント体系）
- `04_frontend.md` § 認証処理（auth.js）
- `05_animations.md` § 認証エラー演出（砂崩れ）

**実装内容**:
- `app/javascript/auth.js` 作成
- **カード切り替え**:
  - ログインカードとサインアップカードを CSS で重ねて配置
  - カードクリックで前後入れ替え
- **ログイン処理**:
  - `POST /users/sign_in`（fetch API + CSRF トークン）
- **サインアップ処理**:
  - `POST /users`（パスワード確認のバリデーション）
- **エラー表示**:
  - 砂崩れアニメーション（認証失敗時）

---

### タスク5: 音声管理・AudioContext初期化 (1-2時間)

**参照仕様書**:
- `04_frontend.md` § 音声再生・AudioContext管理

**実装内容**:
- `app/javascript/common.js` に音声管理機能を追加
- **AudioContext初期化**:
  - `initAudioContext()` 関数実装
  - モダンブラウザの音声自動再生制限対応
  - 「扉をクリック」（index.html）をトリガーとして使用
- **グローバル状態管理**:
  - `audioContext` グローバル変数（初期化状態）
  - `isMuted` グローバル変数（ミュート状態）
- **playSound() 関数を拡張**:
  - ミュート機能対応（`if (isMuted) return`）
  - AudioContext自動初期化
  - 音量パラメータ対応（デフォルト0.5）
  - エラーハンドリング強化
- **ミュート切り替え機能**:
  - `toggleMute()` 関数実装
  - ミュートボタン（🔇/🔊）の動作連携

**実装注意点**:
- `playSound()` は既存のすべての呼び出しと互換性を保つ
- 第1引数（ファイル名）は必須、第2引数（音量）はオプション
- AudioContext初期化時の例外は catch して console.warn でログ

---

### タスク6: LocalStorage連携・トップページでのメモUI実装 (1-2時間)

**参照仕様書**:
- `04_frontend.md` § LocalStorage連携（scratchpad.js）

**実装内容**:

**① scratchpad.js の実装**:
- `app/javascript/scratchpad.js` 作成
- 関数群：`saveScratchpad()`, `loadScratchpad()`, `clearScratchpad()`, `setupAutoSave()`
- 仕様：2,000文字制限、キー名 `dream_diary_scratchpad`、データ形式 `{ content, timestamp }`

**② トップページ（index.html.erb）でのメモUI実装**:
- 「紙片」入力エリア（オーバーレイ表示）をトップページに配置
- テキストエリアに `setupAutoSave()` を適用：入力ごとに自動保存
- LocalStorageからメモを読み込み、存在していれば復元表示
- 「紙片を閉じるボタン」を配置（オーバーレイを非表示にする）

---

## Day 4: CRUD機能統合 + タグ機能

### タスク1: 作成・編集画面実装 (3-4時間)

**参照仕様書**:
- `01_overview.md` § 感情彩色（emotion_color）の実装方針
- `04_frontend.md` § 作成・編集画面（dream_editor.js）
- `04_frontend.md` § 感情彩色に対応した画像パス生成
- `04_frontend.md` § LocalStorage メモのロード（XSS 対策付き）
- `02_database.md` § Dream モデル
- `05_animations.md` § 巻物展開・収束演出
- `05_animations.md` § 保存演出（作成時）
- `05_animations.md` § 保存演出（更新時）
- `dream_diary_asset_list.md` § 1.2.3 巻物
- `dream_diary_asset_list.md` § 1.3.1 巻物（作成UI）

**実装内容**:
- `app/javascript/dream_editor.js` 作成
- **巻物の構造**:
  - 上端/下端画像は **固定** で配置（`img_scroll_top_bottom.png`）
  - 入力欄は **内部スクロール** 対応
  - 紙の質感は CSS（`repeating-linear-gradient` など）で表現
  - 背景色は emotion_color に応じて動的に変更
- **kuromoji.js 導入**:
  - `npm install kuromoji` または CDN 使用
  - 辞書データ読み込み（初回のみ、約6MB）
- **入力フィールド**:
  - タイトル入力（必須、15文字制限、プレースホルダー「夢に名を付ける...」）
  - 夢を見た日（必須、デフォルトで現在日付）
  - 本文入力（テキストエリア、10,000文字制限）
  - 感情彩色選択（4色インク瓶）
    - **アセット選択**: `getEmotionImagePath('img_ink_bottle', emotion_color)` で色別画像を動的に選択
    - emotion_color: 0=peace, 1=chaos, 2=fear, 3=exalt
  - タグ入力（登場人物/場所）
    - タグ名（`name`）のみ入力欄表示
    - 読み仮名（yomi）自動生成（kuromoji.js、hidden input に保持）
- **LocalStorage メモ機能**:
  - 初期化時に `loadScratchpadMemo()` 呼び出し
  - LocalStorage の scratchpad_memo を textarea に読み込み
  - **XSS 対策**: `element.value` プロパティで読み込み（innerHTML 使用禁止）
  - 縮小版巻物（`.scroll-preview`）に `.has-memo` クラスを追加し、CSS グラデーションで書きかけテクスチャを表示
  - 詳細実装は `04_frontend.md` § LocalStorage メモのロード（XSS 対策付き）を参照
  - スタイル実装は `dream_diary_asset_list.md` § 1.2.3 巻物 § 書きかけ状態の表示（LocalStorage メモ有無の視認）を参照
- **保存処理**（API POST/PUT）:
  - リクエストに `title`, `dreamed_at`, `content`, `emotion_color`, `tag_names` (name + yomi) を含める
  - `lucid_dream_flag` は常に `false`（将来の拡張用）
- **Rails 側 XSS 対策**:
  - Dream モデルの `before_save :sanitize_content` で自動サニタイズ
  - `ActionController::Base.helpers.sanitize()` で全タグと属性を除去
  - 詳細は `02_database.md` § Dream モデル § XSS 対策（sanitize_content）を参照
- **保存演出**:
  - **作成時（POST）**: 栞発光 → 巻物収縮 → 瞬き → 書斎へ遷移 → 本棚テクスチャ更新
  - **更新時（PUT）**: 巻物収縮 → 瞬き → 本の実体化 → 一覧へ遷移 → 背表紙が光る

---

### タスク2: タグサジェスト実装 (2-3時間)

**参照仕様書**:
- `04_frontend.md` § タグサジェスト（tag_suggest.js）
- `03_api.md` § 2. タグサジェスト
- `03_api.md` § GET /api/v1/tags/suggest（タグサジェスト）

**実装内容**:
- `app/javascript/tag_suggest.js` 作成
- オートコンプリートUI
- API `/api/v1/tags/suggest` 呼び出し
- デバウンス処理（300ms）
- タグバッジ追加/削除

---

### タスク3: 一覧画面実装 (2-3時間)

**参照仕様書**:
- `04_frontend.md` § 一覧画面（dream_list.js）
- `05_animations.md` § 背表紙ホバー演出（一覧画面）

**実装内容**:
- `app/javascript/dream_list.js` 作成
- 本棚UI（背表紙パーツ配置）
- API `/api/v1/dreams` 呼び出し
- **背表紙表示**:
  - 通常時: タイトル非表示（背表紙の質感のみ）
  - マウスオーバー/1タップ目: タイトルが空中に浮遊表示（15文字まで、縦書き、DotGothic16フォント）
  - 2タップ目/クリック: 詳細モーダルを開く
  - 感情彩色を背表紙画像選択に使用
- ページネーション（瞬きロード）
- フィルタリング（検索結果表示）

---

### タスク4: 詳細・削除実装 (2-3時間)

**参照仕様書**:
- `04_frontend.md` § 詳細表示・削除（dream_detail.js）
- `05_animations.md` § 詳細画面（見開き本）
- `05_animations.md` § 本のページめくり演出（3D回転）
- `05_animations.md` § 削除演出（忘却の儀式）
- `dream_diary_asset_list.md` § 1.2.5 本（詳細 - 見開き表示）

**実装内容**:
- `app/javascript/dream_detail.js` 作成
- **見開き本モーダル表示** (div + CSS ベース):
  - 左ページ: タイトル・日付・タグ表示（固定）
  - 右ページ: 本文表示（ページネーション対応）
  - フレームは CSS で描画（画像アセット不要）
- **ページネーション実装**:
  - BookReader クラス使用（500字/ページで自動分割）
  - `nextPage()` / `prevPage()` メソッド実装
  - ページ番号表示（「3/10」形式）
  - 右ページクリック → 次ページ へ移動
  - 左ページクリック → 前ページ へ移動
- **3D回転めくり演出**:
  - `transform: rotateY()` で 800ms 回転アニメーション
  - 回転中（400ms後）にページ内容を更新
  - 前後両方向対応（forward/backward）
  - 音響: `sfx_page_turn.wav`
- API `/api/v1/dreams/:id` 呼び出し
- **詳細画面「開く時」の演出**:
  - 瞬き（閉眼）中に本棚から本を手に取る動作を隠蔽
  - 瞬き（開眼）後に背景ぼかし適用
  - 瞬き開眼後、本が開くパラパラ漫画（正面閉→半分開き→見開きフレーム）
  - 詳細は `05_animations.md` § 詳細画面（見開き本）
- **編集トリガー**（羽ペン＋ペーパーナイフ）:
  - 右下隅上方に配置
  - クリックで本が閉じるパラパラ漫画（見開き→半分開き→正面閉）
  - 瞬き（閉眼）中にモーダル切り替え
  - 瞬き開眼後、巻物モーダル伸長アニメーション
  - 既存データをロード（title, dreamed_at, content, tags, emotion_color）
  - `lucid_dream_flag` は編集対象外
  - 詳細は `05_animations.md` § 詳細画面（見開き本）
- **削除演出**（忘却の儀式）:
  1. 砂時計クリック → 回転アニメーション
  2. インク滲み演出（文字が霧散）
  3. 本が開いた状態のまま、薄くなって消えていく（opacity フェードアウト 500ms）
     - 「夢日記の削除感を演出」
  4. モーダル閉じる
  5. 一覧画面で背表紙が消える → 隣の本がスライド

---

### タスク5: 書斎初期表示・コールドスタート対応 (1-2時間)

**参照仕様書**:
- `02_database.md` § 初期データ（Seed Data）
- `04_frontend.md` § コールドスタート対応（Day 3 Task 1-2 詳細）

**実装内容**:
- **ユーザー作成時の自動生成**:
  - User モデルの `after_create` コールバックで チュートリアル本「書斎の使い方」を自動生成
  - `02_database.md` § 初期データ実装例を参照

- **書斎画面ロード時の初期表示**:
  - 本棚が空の場合（dreams.length === 1 && title === '書斎の使い方'）を検出
  - 本棚に発光 + 振動エフェクト適用
  - ユーザーがチュートリアル本を読み終えた後、巻物を発光させる
  - 詳細実装は `04_frontend.md` § コールドスタート対応を参照

---

## Day 5: 検索機能 + 演出完成 + テスト + 最終調整

### タスク1: 索引箱（検索）実装 + タグ削除 (3-4時間)

**参照仕様書**:
- `04_frontend.md` § 検索（index_box.js）
- `04_frontend.md` § タグ削除（Day 4 Task 2 詳細）
- `05_animations.md` § タグ削除演出（風化して消滅）
- `03_api.md` § 6. 検索（AND条件）
- `03_api.md` § DELETE /api/v1/tags/:id（タグ削除）

**実装内容**:
- `app/javascript/index_box.js` 作成
- 索引箱モーダルUI
- **タグカード一覧表示**（五十音順）:
  - API `/api/v1/tags` から取得
  - yomi_index でグループ化
  - **タグカード右下に削除ボタン**（img_tag_delete.png）を実装
  - クリック時に crumble-and-fade アニメーション + API DELETE 呼び出し
- **五十音インデックス**:
  - あ行、か行、さ行、た行、な行、は行、ま行、や行、ら行、わ行、英数字、他
  - クリックで該当する yomi_index のタグにジャンプ
- **タグ選択**（ピン留め）
- **2つの検索入力欄**:
  1. タグ絞り込み入力: タグカードを絞り込む（フロントエンド、`name` と `yomi` 対象）
  2. キーワード検索入力: 夢日記のタイトルと本文を検索（API経由）
- **AND検索実行**:
  - API `/api/v1/dreams/search`（選択タグ + キーワード）
- 検索結果 → 一覧画面へ遷移

---

### タスク2: 特殊演出実装 (1-2時間)

**参照仕様書**:
- `05_animations.md` § 夢の氾濫演出
- `03_api.md` § 7. 夢の氾濫

**実装内容**:
- 夢の氾濫（API `/api/v1/dreams/overflow`）
- 窓の歪み演出
- 鏡文字表示（マウスホバーで正像）
- 自動閉鎖（60秒）

---

### タスク3: テスト追加 (2-3時間)

**参照仕様書**:
- `02_database.md` § テスト仕様

**実装内容**:
- AND検索のテスト
- タグサジェストのテスト
- エッジケーステスト（文字数上限、タグ重複など）
- カバレッジ確認（目標80%）

**コマンド**:
```bash
docker compose exec web rspec
# coverage/index.html を開いて確認
```

---

### タスク4: フロントエンド手動テスト (1-2時間)

**実施時期**: Day 4 実装完了後、Day 5 開始前

**テスト方針**: テスト自動化は実施しない。代わりに、実装完了後に手動でチェックリストを実行。

**テスト対象チェックリスト**:

**① 基本機能**
- [ ] **AudioContext初期化**: トップページで扉をクリック → 音声が再生される
- [ ] **ミュート機能**: ミュートボタン（🔇/🔊）クリック → 音声ON/OFF切り替え
- [ ] **ページ遷移演出**: 各画面間の遷移時に瞬き演出が再生される

**② メモ機能（LocalStorage）**
- [ ] **メモ入力**: トップページ紙片にテキスト入力 → 自動保存（DevTools Application タブで確認）
- [ ] **メモ復元**: ページリロード → 入力内容が復元される
- [ ] **メモ上限**: 2000文字超過時に自動切り詰め
- [ ] **メモ新規作成時の利用**: 新規作成画面でメモが初期値として表示される
- [ ] **既存編集時の隔離**: 既存記事編集時は LocalStorage メモは無視される

**③ 認証**
- [ ] **ログイン成功**: 正しい認証情報 → 書斎画面表示
- [ ] **ログイン失敗**: 間違った認証情報 → エラーメッセージ表示（砂崩れ演出）
- [ ] **サインアップ**: 正しい情報 → アカウント作成 → ログイン画面へ
- [ ] **サインアップエラー**: 不正な入力 → バリデーションエラー表示

**④ エラーハンドリング**
- [ ] **400 Bad Request**: バリデーションエラー → フィールド別エラー表示
- [ ] **401 Unauthorized**: セッション切れ → ログイン画面へリダイレクト
- [ ] **404 Not Found**: 削除済みデータアクセス → エラー表示
- [ ] **422 Unprocessable Entity**: 処理不可エラー → ユーザーへの詳細通知
- [ ] **500 Internal Server Error**: サーバーエラー → 再試行促進メッセージ
- [ ] **ネットワークエラー**: オフライン状態 → 通信失敗メッセージ表示

**⑤ 作成・編集機能**
- [ ] **巻物展開**: 新規作成時に巻物モーダルが表示される
- [ ] **感情彩色**: 4色インク瓶を選択 → 背表紙色が変わる
- [ ] **タグ入力**: タグを入力 → 読み仮名が自動生成される
- [ ] **文字数制限**: タイトル15文字、本文10,000文字の制限が機能する
- [ ] **保存演出**: 保存ボタン → 栞発光 → 巻物収縮 → 瞬き → 書斎へ

**⑥ 一覧・詳細表示**
- [ ] **本棚表示**: 本の背表紙が一覧で表示される
- [ ] **背表紙ホバー**: マウスホバー時に タイトルがツールチップで表示
- [ ] **詳細画面開く**: 背表紙クリック → 瞬き → 見開き本表示
- [ ] **ページネーション**: 前後ページボタン で本のページが切り替わる
- [ ] **詳細→編集**: 羽ペンアイコンクリック → 編集モーダル表示
- [ ] **削除演出**: ナイフアイコン → 砂時計回転 → インク滲み演出 → 背表紙が消える

**⑦ 検索機能**
- [ ] **タグ絞り込み**: タグカード選択 → 該当する夢日記のみ表示
- [ ] **キーワード検索**: テキスト入力 → タイトル・本文から検索
- [ ] **AND検索**: タグ + キーワード組み合わせ → 両条件を満たす結果表示

**テスト実施方法**:

```
1. DevTools を開く（F12）
2. Console タブ：エラーメッセージが出ていないか確認
3. Network タブ：API リクエスト/レスポンス（ステータスコード）確認
4. Application タブ：LocalStorage の save/restore 確認
5. 各チェックリストを実行しながら動作確認

テスト期間：実装完了から 1-2時間で全項目実行可能
```

**パス/フェイル判定**:
- **パス**: チェックリスト項目の 90%以上が正常に動作
- **フェイル**: 重大な不具合（エラー表示、画面表示されない等）が発見された場合 → 該当機能の修正

---

### タスク5: 最終調整 (1-2時間)

**参照仕様書**:
- `01_overview.md` § 開発環境セットアップ手順（まとめ）

**実装内容**:
- Docker環境での動作確認
- エラーハンドリング確認
- README作成（起動手順、環境セットアップ）
- `.env.sample` の最終確認

---

## 使い方の例

**例1: Day 2 タスク2（モデル実装）を実行する場合**

```
「Day 2 タスク2を実装してください」
→ 00_task_reference.md で確認
→ 参照: 02_database.md § Dream モデル、Tag モデル、DreamTag モデル（中間テーブル）
→ 該当セクションを読み込んで実装開始
```

**例2: Day 4 タスク1（作成・編集画面）を実行する場合**

```
「Day 4 タスク1を実装してください」
→ 00_task_reference.md で確認
→ 参照: 04_frontend.md § 作成・編集画面（dream_editor.js）、05_animations.md § 保存演出（作成時）、保存演出（更新時）
→ 該当セクションを読み込んで実装開始
```

---

## Day 3開始時の確認事項

実装を円滑に進めるため、Day 3開始時に以下を確認してください。

### 必須確認項目

- [ ] **アセット確認**
  - `dream_diary_asset_list.md` に記載の画像・テクスチャファイルがすべて準備完成
  - `assets/` フォルダ内に整理済み
  - DotGothic16・Sawarabi Mincho フォント CSS 読み込み確認済み
    （Google Fonts CDN: `@import url('https://fonts.googleapis.com/css2?family=DotGothic16&family=Sawarabi+Mincho&display=swap');`）

- [ ] **音声ファイル対応**
  - **本番音声が完成している場合**: 該当ファイルを `assets/sounds/` に配置
  - **本番音声が未完成の場合**:
    - ダミー音声（ビープ音など統一音声）を作成
    - ファイル名は本来のもの（`sfx_scroll_unfurl.wav` など）を使用
    - 中身はすべてダミー音で統一
    - Day 4/5で本番ファイルに置き換え（コード変更不要）

- [ ] **i18n設定確認・補完**
  - Day 2 で実装した `config/locales/ja.yml` が完備されているか確認
  - `03_api.md` § エンドポイント別エラーレスポンス詳細 に記載のエラーに対応するメッセージがすべて存在するか確認
  - 不足しているメッセージがあれば追加

- [ ] **Day 3仕様書の最終確認・微調整**
  - アセット確定後、`04_frontend.md` の仕様内容が実装可能な状態か確認
  - 不足・矛盾がないか確認し、必要に応じて仕様書を微調整
  - 特に以下の点を確認:
    - Task 4: AudioContext初期化・ミュート機能の詳細
    - Task 5: メモUI実装・LocalStorage連携の詳細
    - Task 6-8: 各画面実装の詳細（レイアウト、UIパーツ等）

### 実装時に調整すべき項目

以下の項目は、実装時に画面確認しながら調整してください。仕様書で完全に決定することはできません。

- **UI配置・座標**: 画面サイズ、レイアウト確認後に調整
- **アニメーション時間**: 実際の動作確認で、UX的に最適な時間に調整
- **フォントサイズ**: DotGothic16 適用時の可読性確認後に調整
- **色微調整**: 画面上での見え方を確認後に調整

### 音声ファイル対応の詳細

**ダミー音声を使用する場合の流れ**:

```
Day 2 までに準備:
  統一のダミー音声を作成（例: 100ms のビープ音）

Day 3 実装時:
  ファイル名は本来のもの（04_frontend.md に記載）
  playSound('sfx_scroll_unfurl.wav') → ダミー音再生
  playSound('sfx_book_open.wav') → ダミー音再生
  （コード変更なし）

Day 4/5 で本番対応:
  各音声ファイルの中身をダミーから本番に置き換え
  ファイル名は変わらない
  → コード一切変更不要
```

**メリット**:
- Day 3は本番と同じコードで実装可能
- 音声再生ロジック・タイミングの確認が可能
- Day 4/5での置き換えが簡単

---

このファイルを起点に、各仕様書を効率的に参照して実装を進めてください。
