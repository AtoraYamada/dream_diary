# 演出仕様

## 概要

PS1風レトロアクションゲームの世界観を演出するアニメーション群。

## プロトタイプ実装済み

| 演出 | 状態 | 備考 |
|------|------|------|
| 瞬き | ✓ | closeEyes/openEyes |
| ページ遷移 | ✓ | 瞬き使用 |
| モーダル表示 | ✓ | |
| 巻物展開・収束 | ✓ | |

## 追加実装が必要

| 演出 | 使用シーン |
|------|-----------|
| 音声管理 (AudioContext) | 全ページ |
| 保存演出 (新規) | 夢作成後 |
| 保存演出 (更新) | 夢更新後 |
| 削除演出 (忘却の儀式) | 夢削除時 |
| 本の開閉 | 詳細モーダル |
| ページめくり | 詳細画面 |
| 夢の氾濫 | 書斎・窓クリック |
| 認証エラー (砂崩れ) | ログイン失敗時 |
| 背表紙ホバー | 一覧画面 |

## 設計判断

| 決定 | 理由 |
|------|------|
| CSS アニメーション優先 | パフォーマンス |
| transform 使用 | GPU加速 |
| AudioContext | ブラウザ音声制限対応 |

## 演出詳細

### 瞬き (共通) ✓ 実装済み

| フェーズ | 時間 | easing | CSS |
|---------|------|--------|-----|
| 閉じる | 300ms | ease-out | transform: translateY(0) |
| 閉じ完了後待機 | 200ms | - | callback実行 |
| 開く | 500ms | ease-in | transform: translateY(±100%) |

- トリガー: ページ遷移、ローディング
- 動作: 上下から黒幕が閉じる → 開く
- 効果音: sfx_blink.wav
- 関数: `closeEyes(callback)` → `openEyes()`

### 巻物展開・収束 ✓ 実装済み

| フェーズ | 時間 | easing | 効果音 |
|---------|------|--------|--------|
| 展開 | 400ms | ease-out | sfx_scroll_unfurl.wav |
| 収束 | 300ms | ease-in | sfx_scroll_roll_up.wav |

### 保存演出 (新規作成時)

| ステップ | 演出 | 時間 | 効果音 |
|---------|------|------|--------|
| 1 | 銀の栞が発光 | 200ms | - |
| 2 | 巻物が縮小 | 300ms | sfx_scroll_roll_up.wav |
| 3 | 瞬き（閉じる） | 300ms | sfx_blink.wav |
| 4 | 縮小巻物再表示 | - | - |
| 5 | 瞬き（開く） | 500ms | - |
| 6 | 本実体化（半開→閉） | 600ms | sfx_book_close_heavy.wav |
| 7 | 本が本棚へ飛翔 | 400ms | sfx_zoom_in_out.wav |
| 8 | モーダル閉じ | 300ms | - |

### 保存演出 (更新時)

| ステップ | 演出 | 時間 | 効果音 |
|---------|------|------|--------|
| 1 | 巻物が縮小 | 300ms | sfx_scroll_roll_up.wav |
| 2 | 瞬き（閉じる） | 300ms | sfx_blink.wav |
| 3 | 暗転中に本実体化 | 600ms | sfx_book_close_heavy.wav |
| 4 | 本が暗闇に消える | 400ms | - |
| 5 | 瞬き（開く）で一覧へ | 500ms | - |
| 6 | 背表紙が光る | 300ms | sfx_highlight.wav |

### 削除演出 (忘却の儀式)

| ステップ | 演出 | 時間 | 効果音 |
|---------|------|------|--------|
| 1 | 砂時計逆回転 | 1000ms | sfx_hourglass_rotate.wav |
| 2 | 文字インク霧散 | 800ms | sfx_ink_dissipate.wav |
| 3 | 本フェードアウト | 500ms | sfx_book_vanish.wav |
| 4 | 空隙表示 | - | - |
| 5 | 隣の本スライド | 2000ms後開始、400ms | - |

### 本の開閉

**開く時**

| ステップ | 演出 | 時間 | 効果音 |
|---------|------|------|--------|
| 1 | 瞬き | 800ms | sfx_blink.wav |
| 2 | 背景ぼかし | 300ms | - |
| 3 | 本開き（閉→半開→見開き） | 800ms | sfx_page_turn.wav |

**閉じる時**

| ステップ | 演出 | 時間 | 効果音 |
|---------|------|------|--------|
| 1 | 本閉じ（見開き→閉） | 400ms | sfx_book_close_heavy.wav |
| 2 | 本棚へ戻る | 300ms | - |

### ページめくり (3D回転)

| フェーズ | 時間 | easing | CSS |
|---------|------|--------|-----|
| ページ回転 | 400ms | ease-in-out | rotateY(±180deg) |

- perspective: 1000px
- 効果音: sfx_page_turn.wav

### 夢の氾濫

| フェーズ | 時間 | easing | 効果音 |
|---------|------|--------|--------|
| 窓歪み | 500ms | ease-out | sfx_glass_warp.wav |
| 文字流入 | 1000ms | ease-out | - |
| 鏡文字表示 | 300ms | ease-out | - |
| 正像反転 | 200ms | ease-in-out | - |

- **トリガー:** 書斎の「窓」をクリック
- **解除:** 背景クリック、または60秒放置で自動解除
- API: GET /api/v1/dreams/overflow

### 認証エラー (砂崩れ) ✓ 一部実装済み

| フェーズ | 時間 | easing |
|---------|------|--------|
| 砂崩れ | 800ms | forwards |

```css
@keyframes crumble-and-fade {
  0%   { transform: scale(1) rotate(0deg); opacity: 1; }
  20%  { transform: scale(1.02) rotate(1deg) translateY(-2px); }
  40%  { transform: scale(0.95) rotate(-3deg) translateY(5px); }
  60%  { transform: scale(0.8) rotate(5deg) translateY(10px); }
  80%  { transform: scale(0.5) rotate(10deg) translateY(20px); opacity: 0.5; }
  100% { transform: scale(0.3) translateY(40px); opacity: 0; }
}
```

- **トリガー:** ログイン/サインアップ失敗
- **効果音:** sfx_sand_crumble.wav

### 背表紙ホバー

| 状態 | 演出 | 時間 | easing |
|------|------|------|--------|
| ホバー開始 | タイトル浮遊表示 | 300ms | ease-out |
| ホバーリフト | scale(1.03) translateY(-5px) | 300ms | ease-out |
| ホバー終了 | 元に戻る | 300ms | ease-out |

- **PC (マウス):** ホバー→タイトル浮遊表示、クリック→詳細モーダル
- **モバイル (タッチ):** 1タップ→タイトル浮遊表示、2タップ→詳細モーダル

### 音声管理 (AudioContext)

```javascript
// ユーザーインタラクション後に初期化
let audioContext = null;

function initAudio() {
  if (!audioContext) {
    audioContext = new (window.AudioContext || window.webkitAudioContext)();
  }
  if (audioContext.state === 'suspended') {
    audioContext.resume();
  }
}

// クリック/タップイベントで初期化
document.addEventListener('click', initAudio, { once: true });
```

- BGM (mp3): ループ再生、`audio.loop = true`
- 効果音 (wav): 単発再生

## 実装状況

- [x] 瞬き (プロトタイプ)
- [x] モーダル表示 (プロトタイプ)
- [x] 巻物展開・収束 (プロトタイプ)
- [ ] 音声管理 (AudioContext)
- [ ] 保存演出 (新規)
- [ ] 保存演出 (更新)
- [ ] 削除演出 (忘却の儀式)
- [ ] 本の開閉
- [ ] ページめくり
- [ ] 夢の氾濫演出
- [ ] 認証エラー (砂崩れ)
- [ ] 背表紙ホバー
