# 夢編集画面（夢を編む）

巻物スクロールで既存の夢日記を編集。一覧画面の背景上にモーダル表示。

---

## 要件

- 既存の夢日記を編集
- タイトル、本文、日付、感情彩色、タグ、明晰夢フラグの編集
- タグのサジェスト/オートコンプリート機能
- 感情彩色による巻物の色変化
- 自動保存（LocalStorage）
- 保存成功時の定着の儀式（本が実体化して一覧へ戻る、背表紙が光る）
- 保存失敗時の救済処理（クリップボードコピー）

---

## 設計判断

| 項目 | 選択 | 理由 |
|------|------|------|
| UI形式 | 巻物モーダル | 作成画面と同一のUI/UXを提供 |
| カーソル | 羽ペン（`cursor_quill.png`） | 夢の領域での筆記具を表現 |
| 自動保存先 | LocalStorage（`draft_dream_edit_{id}`） | 保存失敗時の救済、作成画面と隔離 |
| タグサジェスト | debounce 300ms | サーバー負荷とUXのバランス |
| 明晰夢フラグ | データ構造のみ確保、UI未実装 | 将来拡張用 |
| 初期値 | DBの保存データ | LocalStorageは参照しない（隔離） |

---

## 画面構成

| レイヤー | 要素 | 説明 |
|---------|------|------|
| 背景 | 一覧画面（ぼかし） | 一覧画面が減光・ぼかし状態 |
| 前景 | 巻物 | 縦スクロール。上端（画像）＋入力エリア＋下端（画像）。`img_scroll_top_bottom.png` |
| 前景 | 羽ペンカーソル | 入力中のカーソル（`cursor_quill.png`） |
| 前景 | インク瓶（4色） | 感情彩色選択UI（`img_ink_bottle_*.png`） |
| 前景 | 銀の栞 | 保存ボタン（`icon_bookmark_silver.png`） |

---

## 入力フィールド

| フィールド | 必須 | 型 | 制約 | 初期値 | 備考 |
|-----------|------|-----|------|--------|------|
| タイトル | ○ | string | 最大15文字 | DBから | リアルタイム文字数表示 |
| 夢を見た日 | ○ | date | - | DBから | 日付選択 |
| 本文 | ○ | text | 最大10,000文字 | DBから | リアルタイム文字数表示 |
| 感情彩色 | ○ | enum | peace/chaos/fear/elation | DBから | 4色のインク瓶から選択 |
| タグ（登場人物） | - | array | - | DBから | サジェスト/オートコンプリート |
| タグ（場所） | - | array | - | DBから | サジェスト/オートコンプリート |
| 明晰夢チェック | - | boolean | - | DBから | 【将来拡張：データ構造のみ確保、UI未実装】 |

制約詳細は `data.md` 参照。

---

## UI動作

### 編集開始（詳細から）

**トリガー**: 詳細画面の羽ペンとナイフ（`icon_edit_quill_knife.png`）をクリック（`detail.md` 参照）

**動作**:
- 本が閉じるアニメーション（見開き→半開き→閉、600ms）
- SE: `sfx_book_close_heavy.wav`
- 瞬き演出（`animations.md` 参照）
- 巻物展開演出（`animations.md` 参照）
- DBの保存データが初期値としてロード
- LocalStorageは参照しない（作成画面と隔離）
- 編集画面がモーダル表示される

### テキスト入力

**トリガー**: 入力エリアにフォーカス

**動作**:
- 羽ペンカーソルに変化（`cursor_quill.png`）
- 羽ペンの筆記音（`sfx_quill_write.wav`）ループ再生（フォーカス中のみ）
- 入力ごとにLocalStorageへ自動保存（`draft_dream_edit_{id}`）

### 感情彩色の選択

**トリガー**: インク瓶をクリック

**動作**:
1. インクの滴り音（即時）: `sfx_ink_drip.wav`
2. 巻物の紙色変更（即時）: 選択した感情彩色に応じて背景色が変化

### タグ入力

**UI**: 巻物の入力エリア直下に「登場人物」「場所」の入力フィールド

**動作**:
- 入力開始時（300ms debounce後）: サジェストAPI呼び出し
- 過去のタグからサジェスト/オートコンプリート
- 追加されたタグは「×」ボタン付きバッジで表示
- 「×」クリックでタグ削除

**タグ読み仮名の自動生成**:
- kuromoji.js（クライアント側）で読み仮名を生成
- サーバーへ送信時に `yomi` フィールドに含める

### 保存（銀の栞をクリック）

**トリガー**: 銀の栞をクリック

**動作**:
1. バリデーション（クライアント側）
2. API送信（PUT /api/v1/dreams/:id）
3. 通信中: 巻物が震える
4. 成功: 定着の儀式（`animations.md` 参照） → 一覧画面に戻る（背表紙が光る）
5. 失敗: 保存失敗演出（`animations.md` 参照）

**成功時のLocalStorage削除**:
- `draft_dream_edit_{id}` を削除

### 画面外クリック（保存せずに閉じる）

**トリガー**: 巻物の外側（画面外）をクリック

**動作**:
1. 巻物収束演出（`animations.md` 参照）
2. 瞬き演出（`animations.md` 参照）
3. 本が開くアニメーション（閉→半開き→見開き、600ms）
4. SE: `sfx_page_turn.wav`
5. 詳細画面（`detail.md`）に戻る
6. LocalStorageの`draft_dream_edit_{id}`を削除

---

## エラーハンドリング

| 状況 | 対応 |
|------|------|
| バリデーションエラー（422） | エラーメッセージ表示、フォームは維持 |
| 通信エラー | 保存失敗演出、LocalStorage保持、クリップボードコピーボタン表示 |

エラーメッセージは `config/locales/ja.yml` 参照。

---

## データ送受信（API）

### 夢詳細取得

**エンドポイント**: `GET /api/v1/dreams/:id`

**レスポンス（成功: 200）**:
```json
{
  "id": 1,
  "title": "夢のタイトル",
  "content": "夢の本文...",
  "emotion_color": "peace",
  "lucid_dream_flag": false,
  "dreamed_at": "2025-01-15",
  "tags": [
    {"id": 1, "name": "田中", "yomi": "たなか", "category": "person"},
    {"id": 2, "name": "学校", "yomi": "がっこう", "category": "place"}
  ],
  "created_at": "2025-01-15T10:00:00.000Z",
  "updated_at": "2025-01-15T10:00:00.000Z"
}
```

**レスポンス（失敗: 404）**:
```json
{
  "error": "エラー種別",
  "message": "エラーメッセージ（日本語）"
}
```

**補足**: `config/locales/ja.yml`参照

### 夢更新

**エンドポイント**: `PUT /api/v1/dreams/:id`

**リクエスト**:
```json
{
  "dream": {
    "title": "更新後タイトル",
    "content": "更新後本文...",
    "emotion_color": "chaos",
    "lucid_dream_flag": true,
    "dreamed_at": "2025-01-15",
    "tag_attributes": [
      {"name": "田中", "yomi": "たなか", "category": "person"},
      {"name": "学校", "yomi": "がっこう", "category": "place"}
    ]
  }
}
```

**レスポンス（成功: 200）**:
```json
{
  "id": 1,
  "title": "更新後タイトル",
  "content": "更新後本文...",
  "emotion_color": "chaos",
  "lucid_dream_flag": true,
  "dreamed_at": "2025-01-15",
  "tags": [
    {"id": 1, "name": "田中", "yomi": "たなか", "category": "person"},
    {"id": 2, "name": "学校", "yomi": "がっこう", "category": "place"}
  ],
  "created_at": "2025-01-15T10:00:00.000Z",
  "updated_at": "2025-01-15T12:00:00.000Z"
}
```

**レスポンス（失敗: 404）**:
```json
{
  "error": "エラー種別",
  "message": "エラーメッセージ（日本語）"
}
```

**レスポンス（失敗: 422）**:
```json
{
  "errors": [
    "属性名 + エラーメッセージ（日本語）",
    "..."
  ]
}
```

**補足**: エラーメッセージは`config/locales/ja.yml`で定義

### タグサジェスト

**エンドポイント**: `GET /api/v1/tags/suggest`

**クエリパラメータ**:
| パラメータ | 型 | 説明 |
|-----------|-----|------|
| q | string | 検索クエリ |
| category | string | person / place |

**レスポンス（成功: 200）**:
```json
{
  "suggestions": [
    {"id": 1, "name": "田中", "yomi": "たなか", "category": "person"},
    {"id": 2, "name": "太郎", "yomi": "たろう", "category": "person"}
  ]
}
```

---

## 演出

`animations.md` の以下のセクションを参照：
- 編集画面（夢を編む） > テキスト入力
- 編集画面（夢を編む） > 感情彩色の選択
- 編集画面（夢を編む） > 保存せずに閉じる（画面外クリック）
- 定着の儀式（更新・保存成功）
- 保存失敗時の救済処理

---

## 実装状況

### バックエンド（API）

- [x] GET /api/v1/dreams/:id（Dreams#show）
- [x] PUT /api/v1/dreams/:id（Dreams#update）
- [x] Jbuilderビュー（show.json.jbuilder, create.json.jbuilder 使い回し）
- [x] GET /api/v1/tags/suggest（Tags#suggest）
- [x] タグ更新サービス（Dreams::UpdateTagsService）
- [x] タグ読み仮名・インデックス生成

### フロントエンド

- [ ] HTMLビュー（モーダル）
- [ ] JavaScript（app/javascript/edit.js）
- [ ] CSS（app/assets/stylesheets/scroll.css）
- [ ] 画面表示
- [ ] 巻物モーダルUI
- [ ] 既存データ読み込み
- [ ] 入力フォーム（タイトル、本文、日付、感情彩色、タグ）
- [ ] テキスト入力（羽ペンカーソル、筆記音）
- [ ] インク瓶（感情彩色選択）
- [ ] 巻物の紙色変更
- [ ] タグ入力・サジェスト（kuromoji.js連携）
- [ ] LocalStorage読み込み（draft_dream_edit_{id}）
- [ ] LocalStorage自動保存
- [ ] API連携（詳細取得、更新、サジェスト）
- [ ] 定着の儀式（更新成功演出）
- [ ] 通信中演出（巻物が震える）
- [ ] 保存失敗演出
- [ ] エラーハンドリング
- [ ] 画面外クリックで閉じる
- [ ] 演出・SE再生

**Note**: プロトタイプ（`prototype/`）に参考実装あり。Rails本体への統合が必要。
