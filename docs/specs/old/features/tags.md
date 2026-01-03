# タグ機能

## 要件

- 夢作成・編集時にタグを設定できる（登場人物/場所）
- 新規タグは自動作成、既存タグは再利用
- ユーザーは夢作成時にタグをサジェストから選択できる
- ユーザーはタグ一覧を閲覧できる（五十音順）
- ユーザーはタグを削除できる

## 設計判断

| 決定 | 理由 |
|------|------|
| kuromoji.js (クライアント) | 読み仮名自動生成、サーバー負荷回避 |
| 五十音インデックス | 索引箱UIのため |
| ユーザーごとにタグ独立 | プライバシー |
| Dream ⇔ Tag 多対多 | 柔軟なタグ付け |

## データ

### tags テーブル

| カラム | 型 | 制約 |
|--------|-----|------|
| id | bigint | PK |
| user_id | bigint | FK, NOT NULL |
| name | string | NOT NULL, UNIQUE per user |
| yomi | string | NOT NULL |
| yomi_index | integer | NOT NULL, enum |
| category | integer | NOT NULL, enum |
| created_at | datetime | NOT NULL |
| updated_at | datetime | NOT NULL |

### enum: category

| 値 | 名称 |
|----|------|
| 0 | person |
| 1 | place |

### enum: yomi_index

| 値 | 名称 |
|----|------|
| 0-9 | あ, か, さ, た, な, は, ま, や, ら, わ |
| 10 | 英数字 |
| 11 | 他 |

### dream_tags テーブル（中間）

| カラム | 型 | 制約 |
|--------|-----|------|
| id | bigint | PK |
| dream_id | bigint | FK, NOT NULL |
| tag_id | bigint | FK, NOT NULL |
| | | UNIQUE (dream_id, tag_id) |

### アソシエーション

**Tag**
- belongs_to :user
- has_many :dream_tags, dependent: :destroy
- has_many :dreams, through: :dream_tags

**DreamTag**
- belongs_to :dream
- belongs_to :tag

## API

| メソッド | パス | 説明 |
|----------|------|------|
| GET | /api/v1/tags | 一覧取得 |
| GET | /api/v1/tags/suggest | サジェスト（夢作成時） |
| DELETE | /api/v1/tags/:id | 削除 |

### パラメータ

**一覧**
- category: person / place
- yomi_index: あ / か / ... / 英数字 / 他

**サジェスト**
- query: 検索文字列（name OR yomi）

## UI動作

### 画面構成

| 画面 | 場所 | 説明 |
|------|------|------|
| タグ入力 | 作成/編集モーダル内 | サジェスト付き入力フィールド |
| タグ一覧 | 索引箱モーダル | 五十音索引でタグ閲覧・削除 |

### タグ入力（作成/編集画面内）

**構成要素**
- カテゴリ切替（登場人物 / 場所）
- タグ入力フィールド
- サジェストドロップダウン
- 選択済みタグ表示エリア
- 削除ボタン（各タグ）

**操作フロー**
1. カテゴリタブ選択（登場人物 or 場所）
2. 入力開始 → APIサジェスト呼び出し（debounce 300ms）
3. サジェスト選択 or Enter → タグ追加
4. 新規タグ入力時 → kuromoji.jsで読み仮名自動生成
5. タグ横の×クリック → タグ削除

**読み仮名生成**
```javascript
// kuromoji.jsで読み仮名を自動取得
const tokenizer = await kuromoji.builder({ dicPath: '/dict' }).build();
const tokens = tokenizer.tokenize(tagName);
const yomi = tokens.map(t => t.reading || t.surface_form).join('');
```

### タグ一覧（索引箱モーダル）

**構成要素**
- 索引箱外観（img_index_box_exterior.png）
- 索引箱内部（img_index_box_interior.png）
- 五十音タブ（あ〜わ、英数字、他）
- カテゴリフィルタ（登場人物 / 場所 / 全て）
- タグカード一覧
- 削除ボタン（各カード）

**操作フロー**
1. 索引箱クリック → モーダル表示、箱開き演出
2. 五十音タブクリック → API呼び出し、カード表示
3. カテゴリフィルタ切替 → 表示絞り込み
4. タグカードホバー → カード浮き上がり
5. 削除ボタンクリック → 確認 → カード消滅演出

**演出**

| 操作 | 演出 | 時間 | 効果音 |
|------|------|------|--------|
| 索引箱開く | 蓋が開く | 400ms | sfx_index_box_open_close.wav |
| タグカード表示 | フェードイン | 200ms | - |
| タグカード削除 | 紙片崩壊 | 500ms | sfx_paper_crumble.wav |
| 索引箱閉じる | 蓋が閉まる | 300ms | sfx_index_box_open_close.wav |

## 実装状況

- [x] Tag モデル
- [x] DreamTag モデル
- [x] Tags 一覧 API
- [x] Tags サジェスト API
- [x] Tags 削除 API
- [ ] タグサジェスト連携
- [ ] タグ一覧UI連携
- [ ] タグ削除UI連携
