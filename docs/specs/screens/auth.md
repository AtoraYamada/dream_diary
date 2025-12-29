# 認証画面（入館手続き）

現実から夢（書斎）へアクセスするための「手続きの場」。

---

## 画面構成

| 要素 | 説明 |
|------|------|
| 背景 | シュールで幾何学的な廊下 |
| バインダー | 前景に配置、カードを保持 |
| 継続カード（ログイン） | 古びれた紙のデザイン |
| 新規カード（サインアップ） | 綺麗な新しい紙のデザイン |
| 戻るボタン | 左上、トップページへ戻る |

---

## UI動作

### カード切り替え

| 操作 | 動作 |
|------|------|
| カードクリック | スライドアニメーション + sfx_auth_card_slide.wav |

### ログインフォーム

| フィールド | 制約 | 説明 |
|------------|------|------|
| login | 必須 | email または username |
| password | 必須 | 6文字以上 |

### サインアップフォーム

| フィールド | 制約 | 説明 |
|------------|------|------|
| username | 必須, UNIQUE | ユーザー名 |
| email | 必須, UNIQUE, format | メールアドレス |
| password | 必須, 6文字以上 | パスワード |
| password_confirmation | 必須, 一致 | パスワード確認 |

---

## API

### ログイン

**エンドポイント**: `POST /users/sign_in`

**リクエスト**:
```json
{
  "user": {
    "login": "user@example.com",
    "password": "password123"
  }
}
```

**レスポンス（成功: 200）**:
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

**レスポンス（失敗: 401）**:
```json
{
  "error": "Invalid login or password."
}
```

---

### サインアップ

**エンドポイント**: `POST /users`

**リクエスト**:
```json
{
  "user": {
    "username": "newuser",
    "email": "new@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }
}
```

**レスポンス（成功: 201）**:
```json
{
  "message": "Signed up successfully.",
  "user": {
    "id": 2,
    "email": "new@example.com",
    "username": "newuser"
  }
}
```

**レスポンス（失敗: 422）**: エラーメッセージ

---

## エラーハンドリング

エラーメッセージは `config/locales/ja.yml` 参照。

| 状況 | 対応 |
|------|------|
| ログイン失敗 | 砂崩れ演出 + エラーメッセージ表示 |
| サインアップ失敗 | 砂崩れ演出 + エラーメッセージ表示 |

---

## 演出

`animations.md` 認証画面 参照。

- カード切替
- 認証成功（書斎へ遷移）
- 認証失敗（砂崩れ）

---

## 実装状況

- [ ] Deviseセットアップ
- [ ] SessionsController（ログイン）
- [ ] RegistrationsController（サインアップ）
- [ ] 認証画面UI
- [ ] カード切替アニメーション
- [ ] 認証成功演出
- [ ] 認証失敗演出
- [ ] 戻るボタン
