# ロードマップ

## 現状

### プロトタイプ (prototype/)

| 機能 | 状態 | 備考 |
|------|------|------|
| 瞬き演出 | ✓ | |
| モーダル表示 | ✓ | 本が開く閉じる演出なし |
| ページ遷移 | ✓ | ズーム演出なし |
| 巻物展開・収束 | ✓ | |
| レスポンシブ | 未対応 | |
| CSS/JS | ベタ書き | 整理・分割が必要 |

---

## Phase 1: 基盤

| 状態 | タスク | 仕様書 |
|------|--------|--------|
| ✅ | Docker環境構築 | `architecture.md` |
| ✅ | Rails初期化 | `architecture.md` |
| ✅ | Devise導入 | `screens/auth.md` |
| ✅ | RSpec設定 | `architecture.md` |
| ✅ | RuboCop設定 | `architecture.md` |
| ✅ | Brakeman設定 | `architecture.md` |

## Phase 2: モデル

| 状態 | タスク | 仕様書 |
|------|--------|--------|
| ✅ | User モデル | `data.md` |
| ✅ | Dream モデル | `data.md` |
| ✅ | Tag モデル | `data.md` |
| ✅ | DreamTag モデル | `data.md` |
| ⬜ | チュートリアル本自動生成（User作成時） | `screens/list.md` |

## Phase 3: API

| 状態 | タスク | 仕様書 |
|------|--------|--------|
| ✅ | Dreams 一覧 API | `screens/list.md` |
| ✅ | Dreams 詳細 API | `screens/detail.md` |
| ✅ | Dreams 作成 API | `screens/create.md` |
| ✅ | Dreams 更新 API | `screens/edit.md` |
| ✅ | Dreams 削除 API | `screens/detail.md` |
| ✅ | Dreams 検索 API | `screens/search.md` |
| ✅ | Dreams 検索: スペース区切りAND検索 | `screens/search.md` |
| ✅ | Dreams 氾濫 API | `screens/overflow.md` |
| ✅ | Dreams 氾濫: タグ頻度分析 | `screens/overflow.md` |
| ✅ | Tags 一覧 API | `screens/search.md` |
| ✅ | Tags サジェスト API | `screens/create.md` |
| ✅ | Tags 削除 API | `screens/search.md` |

## Phase 4: プロトタイプ移行

演出なし。最低限のUIをプロトタイプより移行。
（既存演出: 瞬き、モーダル、ページ遷移、巻物展開・収束は含まれる）

| 状態 | タスク | 仕様書 |
|------|--------|--------|
| ✅ | 静的ファイル移行 (HTML) | `architecture.md` |
| ✅ | Asset Pipeline設定 | `architecture.md` |
| ⬜ | ERB要素整理・パーシャル化 | `architecture.md` |
| ⬜ | CSS整理・分割 | `architecture.md` |
| ⬜ | JS整理・分割 | `architecture.md` |

## Phase 5: バックエンド連携

UIとバックエンドとの繋ぎこみ。

| 状態 | タスク | 仕様書 |
|------|--------|--------|
| ⬜ | Devise JSON API化 | `screens/auth.md`, Serenaメモリ`csrf_protection_decision.md` |
| ⬜ | login（email OR username）対応 | `screens/auth.md` |
| ⬜ | 認証UI連携 | `screens/auth.md` |
| ⬜ | LocalStorage連携 | `screens/top.md`, `screens/create.md` |
| ⬜ | 書斎画面連携 | `screens/library.md` |
| ⬜ | 作成画面連携 | `screens/create.md` |
| ⬜ | 編集画面連携 | `screens/edit.md` |
| ⬜ | 一覧画面連携 | `screens/list.md` |
| ⬜ | 詳細画面連携 | `screens/detail.md` |
| ⬜ | 削除機能連携 | `screens/detail.md` |
| ⬜ | タグサジェスト連携 | `screens/create.md` |
| ⬜ | タグ一覧UI連携 | `screens/search.md` |
| ⬜ | タグ削除UI連携 | `screens/search.md` |
| ⬜ | 検索機能連携 | `screens/search.md` |
| ⬜ | 夢の氾濫連携 | `screens/overflow.md` |
| ⬜ | ログアウト機能連携 | `screens/logout.md` |

## Phase 6: 追加演出

プロトタイプにない演出を追加。

| 状態 | タスク | 仕様書 |
|------|--------|--------|
| ⬜ | 音声管理 (AudioContext) | `screens/top.md`, `animations.md` |
| ⬜ | 保存演出 (作成時) | `animations.md` |
| ⬜ | 保存演出 (更新時) | `animations.md` |
| ⬜ | 削除演出 (忘却の儀式) | `animations.md` |
| ⬜ | 本の開閉演出 | `animations.md` |
| ⬜ | 本のページめくり | `animations.md` |
| ⬜ | 夢の氾濫演出 | `animations.md` |
| ⬜ | 認証エラー演出 (砂崩れ) | `animations.md` |
| ⬜ | 背表紙ホバー演出 | `animations.md` |
| ⬜ | ログアウト演出 (目覚めの儀式) | `animations.md` |

## Phase 7: 仕上げ

| 状態 | タスク | 仕様書 |
|------|--------|--------|
| ⬜ | E2Eテスト | `architecture.md` |
| ⬜ | レスポンシブ対応 | - |
| ⬜ | 最終調整 | - |

---

## 依存関係

```
Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7
```
