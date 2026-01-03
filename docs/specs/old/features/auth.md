# 認証機能

## 要件

- ユーザーはメールアドレスまたはユーザー名でログインできる
- ユーザーはサインアップできる
- ユーザーはログアウトできる

## 設計判断

| 決定 | 理由 |
|------|------|
| Devise使用 | 標準的、セキュア、開発速度 |
| JSON API対応 | フロントエンドとの分離 |
| email OR username ログイン | ユーザビリティ向上 |

## データ

### users テーブル

| カラム | 型 | 制約 |
|--------|-----|------|
| id | bigint | PK |
| email | string | NOT NULL, UNIQUE |
| username | string | NOT NULL, UNIQUE |
| encrypted_password | string | NOT NULL |
| reset_password_token | string | UNIQUE |
| reset_password_sent_at | datetime | |
| remember_created_at | datetime | |
| created_at | datetime | NOT NULL |
| updated_at | datetime | NOT NULL |

### アソシエーション

- has_many :dreams, dependent: :destroy
- has_many :tags, dependent: :destroy

### バリデーション

- username: presence, uniqueness
- email: Deviseの:validatableモジュールが提供

## API

| メソッド | パス | 説明 |
|----------|------|------|
| POST | /users/sign_in | ログイン |
| POST | /users | サインアップ |
| DELETE | /users/sign_out | ログアウト |

### リクエスト/レスポンス

**ログイン**
```json
// Request
{ "user": { "login": "email or username", "password": "xxx" } }

// Response (成功)
{ "message": "ログインしました", "user": { "id": 1, "email": "...", "username": "..." } }
```

**サインアップ**
```json
// Request
{ "user": { "email": "...", "username": "...", "password": "...", "password_confirmation": "..." } }

// Response (成功)
{ "message": "アカウントを作成しました", "user": { ... } }
```

## UI動作

### 画面構成

| 画面 | パス | 説明 |
|------|------|------|
| トップ | / | 森の扉、境界通過演出 |
| 認証 | /auth | ログイン/サインアップ切替 |

### トップ画面

**構成要素**
- 背景（bg_top_forest_door.png）
- 扉（クリック可能エリア）

**操作フロー**
1. 画面クリック → 境界通過演出
2. 瞬き遷移 → 認証画面へ

**演出**

| 操作 | 演出 | 時間 | 効果音 |
|------|------|------|--------|
| 扉クリック | 境界通過 | - | sfx_boundary_pass.wav |
| 遷移 | 瞬き | 800ms | sfx_blink.wav |

### 認証画面

**構成要素**
- 背景（bg_auth_corridor.png）
- 認証カード（img_auth_card_*.png）
- ログイン/サインアップ切替タブ
- 入力フィールド（メール/ユーザー名/パスワード）
- 送信ボタン
- エラーメッセージエリア

**ログインフォーム**
- ログインID（メールまたはユーザー名）
- パスワード

**サインアップフォーム**
- メールアドレス
- ユーザー名
- パスワード
- パスワード確認

**操作フロー**
1. タブ切替 → カードスライド演出
2. 入力 → リアルタイムバリデーション
3. 送信 → API呼び出し
4. 成功 → 瞬き遷移 → 書斎画面へ
5. 失敗 → 砂崩れ演出 → エラーメッセージ表示

**演出**

| 操作 | 演出 | 時間 | 効果音 |
|------|------|------|--------|
| タブ切替 | カードスライド | 300ms | sfx_auth_card_slide.wav |
| 認証成功 | 瞬き | 800ms | sfx_blink.wav |
| 認証失敗 | 砂崩れ | 800ms | sfx_sand_crumble.wav |
| 書斎入場 | 扉を開く | 500ms | sfx_door_open_heavy.wav |

**エラーハンドリング**
- バリデーションエラー: フィールド下に表示
- 認証失敗: 砂崩れ演出後、エラーメッセージ表示
- 通信エラー: 汎用エラーメッセージ

### ログアウト

**トリガー**: 書斎画面のログアウトボタン

**操作フロー**
1. ログアウトボタンクリック
2. 確認モーダル表示
3. 確認 → API呼び出し
4. 覚醒演出（瞬きを逆再生的に使用）
5. トップ画面へ遷移

## 実装状況

- [x] User モデル
- [ ] Devise JSON API化
- [ ] 認証UI連携
