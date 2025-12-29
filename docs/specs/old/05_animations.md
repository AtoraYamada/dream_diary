# 05. 演出仕様

このファイルは、アプリケーション全体で使用される演出・アニメーションの実装ガイドです。

---

## 瞬き演出（共通）

### 概要
画面遷移時に使用する暗転・開眼アニメーション。世界観の統一と没入感の演出。

### HTML構造

```html
<!-- 全ページの <body> 直下に配置 -->
<div id="blink-overlay" class="blink-overlay"></div>
```

### CSS実装

```css
.blink-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: #000;
  opacity: 0;
  pointer-events: none;
  z-index: 10000; /* 最前面 */
  transition: opacity 0.3s ease-out;
}

.blink-overlay.closing {
  opacity: 1;
  pointer-events: auto;
}

.blink-overlay.opening {
  opacity: 0;
  pointer-events: none;
}
```

### JavaScript実装

**参照**: `04_frontend.md` § common.js § 瞬き演出

### タイミング
- **閉眼時間**: 300ms
- **開眼時間**: 300ms
- **合計**: 600ms（画面遷移全体）

### 使用シーン
- ログイン成功 → 書斎へ
- 書斎 → 一覧へ（本棚クリック）
- 一覧 → 詳細モーダル（背表紙クリック）
- 詳細 → 編集モーダル
- 編集完了 → 書斎 or 一覧へ

---

## 巻物展開・収束演出

### 概要
作成・編集画面の巻物モーダルの表示・非表示アニメーション。

### 展開演出（作成開始）

#### フロー
1. 書斎の机上の「巻物オブジェクト」をクリック
2. **瞬き（閉眼）** 300ms
3. 書斎背景にぼかし適用（`filter: blur(8px) brightness(0.6)`）
4. 机上の縮小版巻物を非表示
5. **瞬き（開眼）** 300ms
6. 画面中央にモーダル巻物が出現
7. **巻物展開アニメーション** 600ms（高さ 0 → 100%）
8. **音響**: `sfx_scroll_unfurl.wav`（巻物を広げる音）

#### CSS実装

```css
.scroll-modal {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 80%;
  max-width: 600px;
  height: 0; /* 初期状態 */
  background: url('/assets/scroll_top.png') top no-repeat,
              url('/assets/scroll_bottom.png') bottom no-repeat,
              var(--color-paper);
  background-size: 100% auto, 100% auto, 100% 100%;
  overflow: hidden;
  z-index: 9000;
  transition: height 0.6s ease-out;
}

.scroll-modal.expanded {
  height: 80vh; /* 展開後 */
}
```

### 収束演出（保存時）

#### フロー
1. 銀の栞クリック
2. **栞発光** 300ms（金色、`filter: drop-shadow(0 0 20px gold)`）
3. **巻物収縮アニメーション** 600ms（高さ 100% → 0）
4. **音響**: `sfx_scroll_roll_up.wav`（巻物の収束音）
5. **瞬き（閉眼）** 300ms
6. 書斎背景のぼかし解除
7. 机上の縮小版巻物を再表示
8. **瞬き（開眼）** 300ms

#### JavaScript実装

```javascript
function playScrollCloseAnimation() {
  const scrollModal = document.getElementById('scroll-modal');

  // 栞発光
  const bookmark = document.getElementById('bookmark');
  bookmark.style.filter = 'drop-shadow(0 0 20px gold)';
  playSound('sfx_bookmark_glow.wav');

  setTimeout(() => {
    // 巻物収縮
    scrollModal.classList.remove('expanded');
    playSound('sfx_scroll_roll_up.wav');

    setTimeout(() => {
      // 瞬き開始
      closeEyes(() => {
        // ぼかし解除、巻物再表示
        document.querySelector('.library-background').style.filter = 'none';
        document.getElementById('desk-scroll').style.display = 'block';

        openEyes();
      });
    }, 600);
  }, 300);
}
```

---

## 保存演出（作成時）

### フロー

1. **栞発光** 300ms
2. **巻物収縮** 600ms
3. **瞬き（閉眼→開眼）** 300ms
   ← 瞬き中は何もしない（暗転するだけ）
   - 機上の縮小版巻物UI を非表示のまま
4. **【瞬き開眼後】本のパラパラ漫画アニメーション** 200ms
   （モーダル内・画面中央で表示、背景はぼかし状態）
   - a. 本：半分開きかけ 100ms
   - b. 本：正面（閉） 100ms
   - **音響**: sfx_book_close_heavy.wav（重厚な閉本音）
   - **同時に**機上の縮小版巻物UI を再表示（「机の上に巻物が戻された」感覚を演出）
5. **本がモーダル背後の本棚（ぼかされた書斎奥）へ縮小しながら飛んでいく** 500ms
6. **モーダルが閉じ、書斎のぼかしが解除される**
7. **書斎に戻る**（巻物は机上に置かれた状態）
8. **本棚の遠景テクスチャ更新**（蔵書数に応じて小/中/大）

### 本棚テクスチャ更新

#### CSS実装

```css
.library-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-size: contain;
  background-repeat: no-repeat;
  background-position: center;
  z-index: 1;
  opacity: 0.5;
  transition: opacity 0.5s ease-out;
}

.library-overlay.small {
  background-image: url('/assets/img_library_overlay_small.png');
}

.library-overlay.medium {
  background-image: url('/assets/img_library_overlay_medium.png');
}

.library-overlay.large {
  background-image: url('/assets/img_library_overlay_large.png');
}
```

#### JavaScript実装

```javascript
/**
 * 本棚テクスチャを更新
 */
function updateLibraryOverlay() {
  const bookCount = getTotalBookCount(); // 総蔵書数を取得
  const overlay = document.getElementById('library-overlay');

  overlay.classList.remove('small', 'medium', 'large');

  if (bookCount > 0 && bookCount <= 5) {
    overlay.classList.add('small');
  } else if (bookCount > 5 && bookCount <= 10) {
    overlay.classList.add('medium');
  } else if (bookCount > 10) {
    overlay.classList.add('large');
  }
}
```

---

## 保存演出（更新時）

### フロー

1. **栞（保存ボタン）クリック**
2. **巻物収縮** 600ms
   - **音響**: sfx_scroll_roll_up.wav（巻物の収束音）
3. **瞬き（閉眼）** 300ms
   ← 瞬き中に以下を実行（場面転換を隠蔽）：
   - a. 本のパラパラ漫画アニメーション（暗闇の中から浮かび上がる）
     - 本：半分開きかけ 100ms
     - 本：正面（閉） 100ms
     - **音響**: sfx_book_close_heavy.wav（重厚な閉本音）
   - b. 実体化した本が暗闇に溶け込むように消える 300ms
   - c. エディタモーダルが閉じる
4. **瞬き（開眼）** 300ms
5. **直接「一覧画面」（本棚ズーム状態）が表示される**
6. **編集した本の背表紙が「キラリ」と光る** 500ms
   - **音響**: sfx_highlight.wav（キラリ音）

### 本の実体化アニメーション

#### HTML構造

```html
<div id="book-materialization" class="book-materialization">
  <img src="/assets/book_half_open.png" class="book-frame frame-1" />
  <img src="/assets/book_closed.png" class="book-frame frame-2" />
</div>
```

#### CSS実装

```css
.book-materialization {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 300px;
  height: 400px;
  opacity: 0;
  z-index: 9500; /* blink-overlay より下 */
  transition: opacity 0.3s ease-out;
}

.book-frame {
  position: absolute;
  width: 100%;
  height: 100%;
  opacity: 0;
}

.frame-1 { animation: show-frame-1 0.1s forwards; }
.frame-2 { animation: show-frame-2 0.1s 0.1s forwards; }

@keyframes show-frame-1 {
  to { opacity: 1; }
}

@keyframes show-frame-2 {
  to { opacity: 1; }
}
```

#### JavaScript実装

```javascript
function playUpdateAnimation() {
  closeEyes(() => {
    // 本の実体化
    const bookMaterialization = document.getElementById('book-materialization');
    bookMaterialization.style.opacity = '1';
    playSound('sfx_book_close_heavy.wav');

    setTimeout(() => {
      // 本が消える
      bookMaterialization.style.opacity = '0';

      setTimeout(() => {
        // 一覧画面へ遷移
        window.location.href = 'list.html?blink=open&highlight=' + dreamId;
      }, 300);
    }, 500);
  });
}
```

### 背表紙が光る演出

#### CSS実装

```css
.book-spine.highlight {
  animation: spine-glow 0.5s ease-out;
}

@keyframes spine-glow {
  0% { filter: brightness(1); }
  50% { filter: brightness(2) drop-shadow(0 0 20px gold); }
  100% { filter: brightness(1); }
}
```

#### JavaScript実装

```javascript
// list.html のロード時
document.addEventListener('DOMContentLoaded', () => {
  const urlParams = new URLSearchParams(window.location.search);
  const highlightId = urlParams.get('highlight');

  if (highlightId) {
    const spine = document.querySelector(`.book-spine[data-id="${highlightId}"]`);
    if (spine) {
      spine.classList.add('highlight');
      playSound('sfx_sparkle.wav'); // キラリ音
    }
  }
});
```

---

## 削除演出（忘却の儀式）

### フロー

1. **砂時計クリック** → 回転アニメーション開始
2. **音響**: `sfx_hourglass_rotate.wav`
3. **インク滲み演出** 1.5s
   - テキストが霧散する
   - **音響**: `sfx_ink_dissipate.wav`
4. **本が開いた状態のまま、薄くなって消えていく** 500ms
   - opacity フェードアウト（「夢日記の削除感を演出」）
   - 音響: なし（インク滲み音の余韻を活かす）
5. **モーダル閉じる**
6. **一覧画面で背表紙が消える** 500ms
   - フェードアウト
   - 隣の本がスライドして隙間を埋める

### 砂時計回転

#### CSS実装

```css
.hourglass-delete-btn.rotating {
  animation: rotate-hourglass 1s infinite linear;
}

@keyframes rotate-hourglass {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}
```

### インク滲み演出

#### CSS実装

```css
.book-page.ink-fade {
  animation: ink-fade-effect 1.5s ease-out forwards;
}

@keyframes ink-fade-effect {
  0% {
    filter: blur(0);
    opacity: 1;
  }
  50% {
    filter: blur(5px);
    opacity: 0.5;
  }
  100% {
    filter: blur(10px);
    opacity: 0;
  }
}
```

### 背表紙削除 + スライド

#### JavaScript実装

```javascript
function removeBookSpine(dreamId) {
  const spine = document.querySelector(`.book-spine[data-id="${dreamId}"]`);
  if (!spine) return;

  // フェードアウト
  spine.style.transition = 'opacity 0.5s ease-out';
  spine.style.opacity = '0';

  setTimeout(() => {
    // DOM から削除
    spine.remove();

    // 隣の本をスライド（CSSのflexboxが自動で処理）
    // 必要に応じて明示的なアニメーションを追加可能
  }, 500);
}
```

### タグ削除演出（風化して消滅）

**トリガー**: タグカード上の img_tag_delete.png（破れた紙片）クリック

**演出フロー**:
1. **音響**: `sfx_sand_crumble.wav`（砂の崩落音）再生
2. **視覚**: タグカードが断片化しながらフェード
   - `opacity: 1 → 0`
   - `transform: scale(1) → scale(0.8) rotate(5deg)`
3. **所要時間**: 0.6秒

**CSS Animation 例**:
```css
.tag-card.deleting {
  animation: crumble-and-fade 0.6s ease-out forwards;
}

@keyframes crumble-and-fade {
  0% {
    opacity: 1;
    transform: scale(1) rotate(0deg);
  }
  100% {
    opacity: 0;
    transform: scale(0.8) rotate(5deg);
  }
}
```

**削除処理**:
1. アニメーション再生
2. API: `DELETE /api/v1/tags/:id`
3. 削除成功後、カード DOM から削除

---

## 詳細画面（見開き本）

### 開く時の演出

**フロー**:
1. 一覧画面で背表紙をクリック
2. **瞬き（閉眼）** 300ms
   ← 瞬き中に本棚から本を手に取る動作を隠蔽
   - モーダルは表示されるが、本は見えていない状態
3. **瞬き（開眼）** 300ms
   ← 開眼時に背景にぼかし適用済み
   - 本は「本：正面（閉）」状態でピントが合っている
4. **【瞬き開眼後】本が開くパラパラ漫画アニメーション** 300ms
   （背景ぼかし状態で、本のみにピント）
   - `本：正面（閉）` 100ms
   - `本：半分開きかけ` 100ms
   - `本：見開きフレーム` 100ms（内容が読める状態）
   - **音響**: sfx_page_turn.wav（ページをめくる音）
5. **モーダル表示完了**（本の内容閲覧可能）

### 閉じる時の演出

**トリガー**: 詳細画面モーダル外をクリック

**演出**:
1. **音響**: sfx_book_close_heavy.wav（重厚な閉本音）再生
2. **視覚**: モーダルがフェードアウト（opacity: 1 → 0）

**所要時間**: 0.3秒（フェードアウト）

**CSS例**:
```css
.modal.closing {
  transition: opacity 0.3s ease-out;
  opacity: 0;
}
```

**備考**: 視点移動がなく、単なる画面表示の切り替えのため、瞬き不要

### 詳細→編集モーダル（切り替え）

**フロー**:
1. 右下隅上方の修正用ペン＋ナイフをクリック
2. **本が閉じるパラパラ漫画アニメーション** 300ms
   （背景は本棚ズーム状態・一覧のまま）
   - `本：見開きフレーム` → `本：半分開きかけ` → `本：正面（閉）`
   - **音響**: sfx_book_close_heavy.wav（重厚な閉本音）
3. **瞬き（閉眼）** 300ms
   ← 瞬き中に以下を実行：
   - a. 詳細モーダルが閉じる
   - b. 巻物モーダルが出現（折り畳み状態：入力部HTMLの高さがゼロ、上端下端の巻物画像のみ表示）
4. **瞬き（開眼）** 300ms
   ← 開眼後、折り畳まれた巻物モーダルが見えている
5. **【瞬き開眼後】巻物の伸長アニメーション** 400ms
   （入力部HTMLの高さが0から100%に伸長）
   - **音響**: sfx_scroll_unfurl.wav（巻物を広げる音）
6. **編集モーダルへ移行完了**

---

## 背表紙ホバー演出（一覧画面）

### 通常時
- タイトル非表示（背表紙の質感のみ）

### マウスオーバー / 1タップ目
- タイトルが空中に浮遊表示（15文字まで）
- アニメーション: フェードイン + 上方向にスライド
- フォント: 縦書き、DotGothic16（ビットマップフォント）

### CSS実装

```css
.book-spine {
  position: relative;
  width: 30px;
  height: 150px;
  cursor: pointer;
  transition: transform 0.2s ease-out;
}

.book-spine:hover {
  transform: translateY(-5px); /* 少し持ち上げる */
}

.floating-title {
  position: absolute;
  top: -20px;
  left: 50%;
  transform: translateX(-50%);
  background-color: rgba(0, 0, 0, 0.8);
  color: var(--color-paper);
  padding: 5px 10px;
  border-radius: 5px;
  font-family: 'DotGothic16', monospace;
  font-size: 14px;
  writing-mode: vertical-rl;
  text-orientation: upright;
  white-space: nowrap;
  opacity: 0;
  pointer-events: none;
  z-index: 10;
  transition: opacity 0.3s ease-out, top 0.3s ease-out;
}

.book-spine:hover .floating-title {
  opacity: 1;
  top: -30px; /* 上方向にスライド */
}
```

---

## 認証エラー演出（砂崩れ）

### 概要
ログイン/サインアップ失敗時、入力文字が砂のように崩れ落ちる演出。

### CSS実装

```css
.auth-error {
  position: absolute;
  bottom: 20px;
  left: 50%;
  transform: translateX(-50%);
  color: var(--color-fear);
  font-family: var(--font-pixel);
  opacity: 0;
  transition: opacity 0.3s ease-out;
}

.auth-error.sand-collapse {
  animation: sand-collapse 2s ease-out;
}

@keyframes sand-collapse {
  0% {
    opacity: 1;
    transform: translateX(-50%) translateY(0);
    filter: blur(0);
  }
  50% {
    opacity: 0.5;
    transform: translateX(-50%) translateY(10px);
    filter: blur(2px);
  }
  100% {
    opacity: 0;
    transform: translateX(-50%) translateY(20px);
    filter: blur(5px);
  }
}
```

---

## 夢の氾濫演出

### 概要
書斎の窓をクリックすると、ランダムな夢の断片が鏡文字として窓に表示される特殊演出。

### フロー

1. **窓クリック**
2. **窓の歪み開始** 500ms
3. **鏡文字が浮かび上がる** 1s
   - 感情彩色の色がついた文字が液体のように流れ込む
   - **音響**: `sfx_window_distortion.wav`
4. **マウスホバーで正像に反転**
   - 窓の縁の光が強く波打つ
5. **解除条件**:
   - 鏡文字の外側（背景）をクリック
   - 60秒間放置で自動解除

### CSS実装

```css
.window-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.5);
  z-index: 9500;
  display: none;
}

.window-overlay.active {
  display: block;
}

.mirror-text {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%) scaleX(-1); /* 鏡文字 */
  font-size: 24px;
  color: var(--color-peace); /* 感情彩色 */
  text-shadow: 0 0 10px currentColor;
  opacity: 0;
  animation: mirror-text-appear 1s ease-out forwards;
}

.mirror-text:hover {
  transform: translate(-50%, -50%) scaleX(1); /* 正像に反転 */
}

@keyframes mirror-text-appear {
  from {
    opacity: 0;
    filter: blur(10px);
  }
  to {
    opacity: 1;
    filter: blur(0);
  }
}
```

---

## 本のページめくり演出（3D回転）

### 概要
詳細モーダルで本のページを移動する時の、3D回転を使っためくり演出。

### フロー

**次ページへ（右クリック）**:
1. 右ページが Y軸中心に **右側に180度回転**（0.8s）
2. 回転中（400ms後）にページ内容を更新
3. 回転完了後、新しいページが表示される
4. **音響**: `sfx_page_turn.wav`

**前ページへ（左クリック）**:
1. 右ページが Y軸中心に **左側に180度回転**（0.8s）
2. 回転中（400ms後）にページ内容を更新
3. 回転完了後、前のページが表示される
4. **音響**: `sfx_page_turn.wav`

### CSS実装

```css
/* ページ要素の3D対応 */
.book-open-frame {
  perspective: 1000px;
}

.right-page {
  transition: transform 0.8s cubic-bezier(0.68, -0.55, 0.265, 1.55);
  transform-style: preserve-3d;
  transform: rotateY(0deg);
}

/* 次ページへ回転（右に180度） */
.right-page.flip-out-forward {
  transform: rotateY(-180deg);
  opacity: 0;
  pointer-events: none;
}

/* 前ページへ回転（左に180度） */
.right-page.flip-out-backward {
  transform: rotateY(180deg);
  opacity: 0;
  pointer-events: none;
}

/* ページネーション UI */
.page-number {
  text-align: center;
  font-size: 12px;
  color: #666;
  margin-top: 20px;
  font-family: var(--font-pixel);
}

.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 20px;
  margin-top: 10px;
}

.page-nav-btn {
  padding: 8px 16px;
  background: transparent;
  border: 1px solid #999;
  color: #666;
  font-family: var(--font-pixel);
  cursor: pointer;
  font-size: 12px;
}

.page-nav-btn:hover {
  border-color: #333;
  color: #333;
}

.page-nav-btn:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}
```

### JavaScript実装

**参照**: `04_frontend.md` § 詳細表示・削除（dream_detail.js） § ページネーション（BookReader クラス）

### タイミング

| フェーズ | 時間 | 説明 |
|---------|------|------|
| 回転開始 | 0ms | クラス追加で回転アニメーション開始 |
| 中間地点 | 400ms | ページ内容を更新（回転中で見えない） |
| 回転完了 | 800ms | アニメーション終了、新ページ表示 |

### ページ分割ルール

- **1ページあたりの文字数**: 500文字（固定）
- **計算方法**: JavaScript で `regex.match()` で自動分割
- **ページ番号表示**: 「3/10」形式

---

## アニメーションタイミング一覧

| 演出 | 時間 | 音響 | トリガー |
|-----|------|------|---------|
| 瞬き（閉眼） | 300ms | sfx_blink.wav | 画面遷移開始 |
| 瞬き（開眼） | 300ms | - | 画面遷移完了 |
| 巻物展開 | 600ms | sfx_scroll_unfurl.wav | 作成開始 |
| 巻物収縮 | 600ms | sfx_scroll_roll_up.wav | 保存開始 |
| 栞発光 | 300ms | sfx_bookmark_glow.wav | 保存ボタン |
| 本の実体化 | 200ms | sfx_book_close_heavy.wav | 更新時 |
| 背表紙が光る | 500ms | sfx_sparkle.wav | 更新完了 |
| 砂時計回転 | 1s（無限） | sfx_hourglass_rotate.wav | 削除ボタン |
| インク滲み | 1.5s | sfx_ink_dissipate.wav | 削除処理 |
| 背表紙削除 | 500ms | - | 削除完了 |
| 砂崩れ | 2s | sfx_sand_crumble.wav | 認証エラー |
| 窓の歪み | 500ms | sfx_window_distortion.wav | 夢の氾濫 |
| 鏡文字出現 | 1s | - | 夢の氾濫 |
| ページめくり（次） | 800ms | sfx_page_turn.wav | 右ページクリック |
| ページめくり（前） | 800ms | sfx_page_turn.wav | 左ページクリック |

---

このファイルは、演出・アニメーションの実装ガイドです。
Day 4-5（CRUD機能統合、演出完成）で参照してください。
