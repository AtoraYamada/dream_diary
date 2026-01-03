# アーキテクチャ

## 技術スタック

| カテゴリ | 技術 | バージョン |
|---------|------|-----------|
| **言語** | Ruby | 3.3.10 |
| | JavaScript | ES6+ |
| **フレームワーク** | Ruby on Rails | 7.2.3 |
| **データベース** | PostgreSQL | 15 |
| **認証** | Devise | 4.9+ |
| **テスト** | RSpec | 8.0+ |
| | FactoryBot | 6.2+ |
| | shoulda-matchers | 7.0+ |
| | SimpleCov | 0.22+ |
| **ページネーション** | Kaminari | 1.2+ |
| **JSON API** | Jbuilder | 2.12+ |
| **CORS** | rack-cors | 3.0+ |
| **コンテナ** | Docker Compose | - |
| **読み仮名生成** | kuromoji.js | 0.1+ |

## 仕様書構造

このプロジェクトは**画面別（screens/）**で仕様を管理。

```
docs/specs/
├── architecture.md      # 本ファイル
├── roadmap.md           # タスク一覧・進捗管理
├── data.md              # データ定義
├── animations.md        # 演出仕様
└── screens/             # 画面別仕様書
    ├── top.md
    ├── auth.md
    ├── library.md
    ├── list.md
    ├── create.md
    ├── detail.md
    ├── edit.md
    ├── search.md
    └── overflow.md
```

**選択理由**: UI中心のアプリケーションで、各画面が明確に分かれており、画面単位での実装が効率的なため。

## アーキテクチャ構成

```
Browser (Vanilla JS)
  ↓ Fetch API
Rails 7.2 JSON API (/api/v1/*)
  ↓
PostgreSQL 15
```

### ファイル構成

| レイヤー | パス |
|---------|------|
| ビュー | app/views/pages/*.html.erb |
| JavaScript | app/javascript/*.js |
| コントローラ | app/controllers/api/v1/*.rb |
| Concerns | app/controllers/concerns/api/*.rb |
| サービス | app/services/**/*.rb |
| モデル | app/models/*.rb |

### サービスクラス

| クラス | 用途 |
|--------|------|
| Dreams::AttachTagsService | タグ付与 |
| Dreams::UpdateTagsService | タグ更新 |
| Dreams::OverflowService | 夢の氾濫 |
| ServiceResult | 処理結果ラッパー |

## 設計判断

| 決定事項 | 選択 | 理由 |
|---------|------|------|
| フロントエンド | Vanilla JS | 既存プロトタイプ活用 |
| バックエンド | Rails JSON API | Devise統合、開発速度 |
| 認証 | Devise + JSON | 標準的、セキュア |
| データ構造 | Dream ⇔ Tag (多対多) | 柔軟なタグ付け |
| ページ分割 | 500字/ページ | 読みやすさ考慮 |
| タグ読み仮名 | kuromoji.js (クライアント) | サーバー負荷回避 |
| 複雑なロジック | Service Object | Fat Controller回避 |
| LocalStorage | 端末固有（同期なし） | オフライン優先、シンプル設計 |
| モバイル操作 | 2段階タップ（1.タイトル表示、2.詳細遷移） | ホバー非対応端末への配慮 |
| ナビゲーション制御 | history.pushState + ブラウザバック対応 | SPA的UX、未保存時警告 |
| 保存失敗時の救済 | LocalStorage保持 + クリップボードコピー | データ喪失防止 |

## フロントエンド構成

### JavaScript構成

| ファイル | 役割 |
|---------|------|
| app/javascript/application.js | Turboエントリポイント |
| app/javascript/common.js | 共通関数（瞬き、音声、LocalStorage） |
| app/javascript/auth.js | 認証画面（ログイン、サインアップ） |
| app/javascript/library.js | 書斎画面（本棚、窓、氾濫） |
| app/javascript/list.js | 一覧画面（巻物、編集モーダル） |
| app/javascript/detail.js | 詳細画面（本の開閉、ページめくり） |
| app/javascript/create.js | 作成画面（巻物、タグサジェスト） |

### 共通関数（common.js）

| 関数 | 用途 |
|------|------|
| closeEyes(callback) | 瞬き演出（閉じる） |
| openEyes() | 瞬き演出（開く） |
| initiateBlinkTransition(callback) | 瞬き遷移 |
| playSound(sfxFileName) | 効果音再生 |
| saveToLocalStorage(key, data) | LocalStorage保存 |
| loadFromLocalStorage(key) | LocalStorage読込 |
| navigateWithBlink(url, sfx) | 瞬き遷移＋画面遷移 |
| apiRequest(path, options) | API呼び出しラッパー |

### CSS構成

| ファイル | 役割 |
|---------|------|
| app/assets/stylesheets/application.css | エントリポイント |
| app/assets/stylesheets/base.css | リセット、変数定義 |
| app/assets/stylesheets/layout.css | 共通レイアウト |
| app/assets/stylesheets/blink.css | 瞬き演出 |
| app/assets/stylesheets/modal.css | モーダル共通 |
| app/assets/stylesheets/scroll.css | 巻物スタイル |
| app/assets/stylesheets/book.css | 本スタイル |
| app/assets/stylesheets/auth.css | 認証画面固有 |
| app/assets/stylesheets/library.css | 書斎画面固有 |

### API連携パターン

```javascript
// CSRF対応のfetchラッパー
async function apiRequest(path, options = {}) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  const response = await fetch(`/api/v1${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken,
      ...options.headers,
    },
  });
  if (!response.ok) throw new Error(`API Error: ${response.status}`);
  return response.json();
}

// 使用例
const dreams = await apiRequest('/dreams');
await apiRequest('/dreams', { method: 'POST', body: JSON.stringify({ dream: {...} }) });
```

## アセット

詳細は `docs/dream_diary_asset_list.md` を参照。

### 画像アセット

#### 背景
| ファイル | 用途 |
|---------|------|
| bg_top_forest_door.png | トップ画面（森の扉） |
| bg_auth_corridor.png | 認証画面（廊下） |
| bg_library_desk.png | 書斎（机・窓・鏡・壁） |
| bg_library_wall_up.png | 一覧/詳細（壁アップ） |
| bg_stone_wall_dark.png | 額縁（4:3外側余白） |

#### 本棚
| ファイル | 用途 |
|---------|------|
| img_bookshelf_empty.png | 空の本棚 |
| img_bookshelf_small.png | 蔵書1-3冊 |
| img_bookshelf_medium.png | 蔵書4-7冊 |
| img_bookshelf_large.png | 蔵書8冊以上 |

#### 巻物
| ファイル | 用途 |
|---------|------|
| img_scroll_top_bottom.png | 巻物上端/下端フレーム |
| img_scroll_mini_blank.png | 縮小巻物（白紙） |
| img_scroll_mini_draft.png | 縮小巻物（書きかけ） |

#### 本（感情彩色別 x4）
| 種類 | ファイル命名規則 |
|------|-----------------|
| 背表紙 | img_book_spine_{peace,chaos,fear,elation}.png |
| 閉じた本 | img_book_closed_{peace,chaos,fear,elation}.png |
| 半開きの本 | img_book_half_open_{peace,chaos,fear,elation}.png |
| 見開きフレーム | img_book_open_frame_{peace,chaos,fear,elation}.png |

#### インク壺（感情彩色別 x4）
| ファイル | 用途 |
|---------|------|
| img_ink_bottle_{peace,chaos,fear,elation}.png | 感情選択UI |

#### 索引箱・タグ
| ファイル | 用途 |
|---------|------|
| img_index_box_exterior.png | 索引箱外観 |
| img_index_box_interior.png | 索引箱内部 |
| img_tag_card_base.png | タグカード |
| img_tag_delete.png | タグ削除ボタン |

#### 認証
| ファイル | 用途 |
|---------|------|
| img_binder.png | バインダー |
| img_auth_card_in.png | ログインカード |
| img_auth_card_up.png | サインアップカード |

#### UI/カーソル
| ファイル | 用途 |
|---------|------|
| cursor_quill.png | 羽ペンカーソル（夢の領域） |
| cursor_pencil.png | 鉛筆カーソル（現実） |
| icon_back.png | 戻るボタン |
| icon_hourglass_antique.png | 削除トリガー（砂時計） |
| icon_bookmark_silver.png | 保存トリガー（銀の栞） |
| icon_edit_quill_knife.png | 編集トリガー |
| img_scratchpad_paper.png | 殴り書き紙片 |

### 音声アセット

#### 汎用
| ファイル | 用途 | 再生方式 |
|---------|------|---------|
| sfx_blink.wav | 画面暗転 | 単発 |
| sfx_screen_slide.wav | 画面移動 | 単発 |
| sfx_ui_confirm.wav | 選択・決定 | 単発 |
| sfx_glitch_dissonance.wav | 保存失敗 | 単発 |

#### トップ画面
| ファイル | 用途 | 再生方式 |
|---------|------|---------|
| sfx_door_open_heavy.wav | 扉を開く | 単発 |
| sfx_pencil_write.wav | 鉛筆筆記 | ループ |

#### 認証
| ファイル | 用途 | 再生方式 |
|---------|------|---------|
| sfx_boundary_pass.wav | ログイン成功 | 単発 |
| sfx_auth_card_slide.wav | カード切替 | 単発 |
| sfx_sand_crumble.wav | 認証失敗 | 単発 |

#### 書斎
| ファイル | 用途 | 再生方式 |
|---------|------|---------|
| sfx_library_ambience.mp3 | 環境音BGM | ループ |
| sfx_zoom_in_out.wav | ズーム移動 | 単発 |

#### 作成・編集
| ファイル | 用途 | 再生方式 |
|---------|------|---------|
| sfx_ink_drip.wav | 感情選択 | 単発 |
| sfx_quill_write.wav | 羽ペン筆記 | ループ |
| sfx_scroll_unfurl.wav | 巻物展開 | 単発 |
| sfx_scroll_roll_up.wav | 巻物収束 | 単発 |
| sfx_book_close_heavy.wav | 本を閉じる | 単発 |
| sfx_book_vanish.wav | 本棚へ吸入 | 単発 |
| sfx_highlight.wav | 更新完了の光 | 単発 |

#### 詳細
| ファイル | 用途 | 再生方式 |
|---------|------|---------|
| sfx_page_turn.wav | ページめくり | 単発 |
| sfx_hourglass_rotate.wav | 削除開始 | 単発 |
| sfx_ink_dissipate.wav | 文字霧散 | 単発 |

#### 索引箱
| ファイル | 用途 | 再生方式 |
|---------|------|---------|
| sfx_pin.wav | タグ選択 | 単発 |
| sfx_index_box_open_close.wav | 索引箱開閉 | 単発 |
| sfx_tag_card_flip.wav | カードめくり | 単発 |

#### 夢の氾濫
| ファイル | 用途 | 再生方式 |
|---------|------|---------|
| sfx_glass_warp.wav | 窓歪み | 単発 |

## デザインシステム

### フォント

| 領域 | フォント |
|------|---------|
| 現実 (トップ) | sans-serif |
| 夢の領域 | DotGothic16, Klee One |

### 感情彩色 (emotion_color)

| 値 | 名称 | カラーコード |
|----|------|-------------|
| 0 | peace | #a0a9a6 |
| 1 | chaos | #b07a70 |
| 2 | fear | #838387 |
| 3 | elation | #ca9e63 |

## API一覧

各画面仕様書（`screens/*.md`）に詳細定義あり。

### 認証

| メソッド | エンドポイント | 用途 |
|---------|---------------|------|
| POST | /users/sign_in | ログイン |
| POST | /users | サインアップ |
| DELETE | /users/sign_out | ログアウト |

### 夢

| メソッド | エンドポイント | 用途 |
|---------|---------------|------|
| GET | /api/v1/dreams | 一覧取得 |
| GET | /api/v1/dreams/search | 検索 |
| GET | /api/v1/dreams/:id | 詳細取得 |
| POST | /api/v1/dreams | 作成 |
| PUT | /api/v1/dreams/:id | 更新 |
| DELETE | /api/v1/dreams/:id | 削除 |
| GET | /api/v1/dreams/overflow | 氾濫テキスト取得 |

### タグ

| メソッド | エンドポイント | 用途 |
|---------|---------------|------|
| GET | /api/v1/tags | 一覧取得 |
| GET | /api/v1/tags/suggest | サジェスト |
| DELETE | /api/v1/tags/:id | 削除 |

## テスト方針

| 対象 | 手法 |
|------|------|
| バックエンド | TDD (RSpec) |
| フロントエンド | 手動 + E2E (Capybara) |
| セキュリティ | Brakeman |
| Lint | RuboCop |
| カバレッジ目標 | 80%+ |
