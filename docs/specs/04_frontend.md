# 04. フロントエンド実装

## ファイル構成

```
app/
├── javascript/
│   ├── common.js           # 共通処理（瞬き演出、音声、初期化）
│   ├── auth.js             # 認証処理（ログイン/サインアップ）
│   ├── scratchpad.js       # LocalStorage連携（殴り書きメモ）
│   ├── dream_editor.js     # 作成・編集画面
│   ├── dream_list.js       # 一覧画面（本棚）
│   ├── dream_detail.js     # 詳細表示・削除
│   ├── tag_suggest.js      # タグサジェスト
│   └── index_box.js        # 検索（索引箱）
├── assets/
│   ├── stylesheets/
│   │   └── style.css       # 共通CSS（既存480行）
│   └── images/             # 画像素材
│   └── sounds/             # 音声素材
└── views/
    └── pages/
        ├── index.html.erb  # トップページ
        ├── auth.html.erb   # 認証画面
        ├── library.html.erb # 書斎（メイン）
        └── list.html.erb   # 一覧画面
```

---

## 共通処理（common.js）

### 役割
- 瞬き演出（画面遷移時の暗転・開眼）
- 音声再生管理
- CSRF トークン取得
- グローバルユーティリティ関数

### 主要関数

#### 瞬き演出

```javascript
/**
 * 瞬き演出（閉眼）
 * @param {Function} callback - 閉眼完了後に実行する処理
 */
function closeEyes(callback) {
  const blinkOverlay = document.getElementById('blink-overlay');
  blinkOverlay.classList.add('closing');

  setTimeout(() => {
    if (callback) callback();
  }, 300); // 300ms で閉眼完了
}

/**
 * 瞬き演出（開眼）
 */
function openEyes() {
  const blinkOverlay = document.getElementById('blink-overlay');
  blinkOverlay.classList.remove('closing');
  blinkOverlay.classList.add('opening');

  setTimeout(() => {
    blinkOverlay.classList.remove('opening');
  }, 300); // 300ms で開眼完了
}

/**
 * 瞬きを伴う画面遷移
 * @param {string} url - 遷移先URL
 */
function navigateWithBlink(url) {
  closeEyes(() => {
    // URLに ?blink=open を付与
    const separator = url.includes('?') ? '&' : '?';
    window.location.href = `${url}${separator}blink=open`;
  });
}

/**
 * ページロード時の開眼チェック
 */
function checkAndOpenEyes() {
  const urlParams = new URLSearchParams(window.location.search);
  if (urlParams.get('blink') === 'open') {
    openEyes();
    // URLから ?blink=open を削除（履歴をクリーンに）
    window.history.replaceState({}, '', window.location.pathname);
  }
}
```

#### 音声再生・AudioContext管理

**グローバル状態管理**:
```javascript
// AudioContext初期化フラグ（ブラウザ制限対応）
let audioContext = null;
let isMuted = false; // ミュート状態
```

**AudioContext初期化**（ブラウザの音声自動再生制限対応）:
```javascript
/**
 * AudioContextを初期化・レジューム
 * モダンブラウザはユーザーインタラクションが必要
 * 「扉をクリック」を初回トリガーとして使用
 */
function initAudioContext() {
  if (audioContext) return; // 既に初期化済み

  try {
    const audioContextClass = window.AudioContext || window.webkitAudioContext;
    audioContext = new audioContextClass();

    if (audioContext.state === 'suspended') {
      audioContext.resume().then(() => {
        console.log('[Audio] AudioContext resumed');
      });
    }
  } catch (error) {
    console.warn('[Audio] AudioContext not supported:', error);
  }
}
```

**音声再生関数**（ミュート機能対応）:
```javascript
/**
 * 音声再生
 * @param {string} filename - 音声ファイル名
 * @param {number} volume - 音量（0.0-1.0、デフォルト0.5）
 */
function playSound(filename, volume = 0.5) {
  // ミュート状態チェック
  if (isMuted) {
    console.log(`[Muted] ${filename}`);
    return;
  }

  // AudioContext未初期化の場合は初期化
  if (!audioContext) {
    initAudioContext();
  }

  try {
    const audio = new Audio(`/assets/sounds/${filename}`);
    audio.volume = volume;
    audio.play().catch(err => {
      console.warn(`[Audio] Playback failed (${filename}):`, err);
    });
  } catch (error) {
    console.warn(`[Audio] Error creating audio element:`, error);
  }
}

/**
 * ミュート状態をトグル
 * @returns {boolean} 新しいミュート状態
 */
function toggleMute() {
  isMuted = !isMuted;
  console.log(`[Audio] ${isMuted ? 'Muted' : 'Unmuted'}`);
  return isMuted;
}
```

#### CSRF トークン

```javascript
/**
 * CSRF トークンを取得
 * @returns {string} CSRF トークン
 */
function getCsrfToken() {
  return document.querySelector('meta[name="csrf-token"]').content;
}
```

#### ページ初期化パターン

**トップページ（index.html.erb）での初期化**:
```javascript
/**
 * ページロード時に実行
 * - 瞬き演出チェック（前ページからの遷移）
 * - ページ初期化（扉クリックハンドラー登録）
 */
document.addEventListener('DOMContentLoaded', () => {
  // 1. 前ページからの遷移による開眼チェック
  checkAndOpenEyes();

  // 2. 扉クリックハンドラー
  const forestDoor = document.getElementById('forest-door');
  if (forestDoor) {
    forestDoor.addEventListener('click', () => {
      // ⭐ AudioContextを初期化（ブラウザ制限対応）
      // 「扉をクリック」がユーザーインタラクションのトリガー
      initAudioContext();

      // 扉の音を再生
      playSound('sfx_door_open_heavy.wav');

      // 認証画面へ遷移
      navigateWithBlink('auth.html');
    });
  }

  // 3. ミュートボタンの初期化
  const muteButton = document.getElementById('mute-button');
  if (muteButton) {
    muteButton.addEventListener('click', (e) => {
      e.stopPropagation(); // イベント伝播を防止

      const newMuteState = toggleMute();
      muteButton.textContent = newMuteState ? '🔇' : '🔊';
      playSound('sfx_ui_confirm.wav');
    });
  }
});
```

**重要な実装ポイント**:
1. **AudioContext初期化のタイミング**: 必ずユーザーインタラクション（クリック）内で実行
2. **ミュートボタンの位置**: 常に表示可能（ページ遷移時も状態を保持）
3. **互換性**: `initAudioContext()` は複数回呼ばれてもOK（既に初期化済みなら return）

#### デザインシステム（フォント体系）

詳細は `01_overview.md` § デザインシステムを参照してください。実装時の重要ポイント：

**フォント切り替え**:
```javascript
// auth.html, library.html, list.html では html に after-door クラスを付与
document.documentElement.classList.add('after-door');

// CSS で制御
// html:not(.after-door) → font-family: var(--font-serif);        // トップページ
// html.after-door       → font-family: var(--font-pixel);        // 夢の領域
```

**CSS変数の定義**（style.css に追加）:
```css
:root {
  --font-serif: serif;                    /* 現実（トップページ） */
  --font-pixel: 'DotGothic16', monospace; /* 夢の領域 */
  --color-peace: #d4c5b9;
  --color-chaos: #8b4c4c;
  --color-fear: #4a5568;
  --color-elation: #c9a854;
}
```

#### fetch ヘルパー

```javascript
/**
 * API リクエストヘルパー
 * @param {string} url - エンドポイント
 * @param {Object} options - fetch オプション
 * @returns {Promise} レスポンス
 */
async function apiRequest(url, options = {}) {
  const headers = {
    'Content-Type': 'application/json',
    'X-CSRF-Token': getCsrfToken(),
    ...options.headers
  };

  try {
    const response = await fetch(url, { ...options, headers });
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
    return response.json();
  } catch (error) {
    console.error('API request failed:', error);
    throw error;
  }
}
```

#### 感情彩色に対応した画像パス生成

```javascript
/**
 * emotion_color に対応した画像パスを生成
 * @param {string} baseName - 画像の基本名（例：img_book_spine）
 * @param {number} emotionColor - emotion_color の値（0-3）
 * @returns {string|null} 画像パス、または null（無効な値の場合）
 */
function getEmotionImagePath(baseName, emotionColor) {
  const emotionMap = {
    0: 'peace',
    1: 'chaos',
    2: 'fear',
    3: 'elation'
  };

  const emotionKey = emotionMap[emotionColor];
  if (!emotionKey) {
    console.warn(`Invalid emotion_color: ${emotionColor}`);
    return null;
  }

  return `/assets/${baseName}_${emotionKey}.png`;
}

// 使用例
// const spineImagePath = getEmotionImagePath('img_book_spine', 0); // '/assets/img_book_spine_peace.png'
// const bookImagePath = getEmotionImagePath('img_book_closed', 2);  // '/assets/img_book_closed_fear.png'
```

**使用箇所**:
- **dream_editor.js**: インク瓶UI の表示（感情色選択時）
- **dream_list.js**: 背表紙 の表示（本棚UI）
- **dream_detail.js**: 本の各状態（正面・半開き・見開き）の表示

---

## 認証処理（auth.js）

### 役割
- ログイン/サインアップ処理
- カード切り替えアニメーション
- エラー表示（砂崩れ演出）

### 主要関数

```javascript
/**
 * カード切り替え
 */
function switchCard() {
  const loginCard = document.getElementById('login-card');
  const signupCard = document.getElementById('signup-card');

  loginCard.classList.toggle('front');
  signupCard.classList.toggle('front');

  playSound('sfx_card_slide.wav');
}

/**
 * ログイン処理
 * @param {Object} credentials - { login, password }
 * login: email または username
 */
async function login(credentials) {
  try {
    const data = await apiRequest('/users/sign_in', {
      method: 'POST',
      body: JSON.stringify({ user: credentials })
    });

    playSound('sfx_boundary_cross.wav'); // 境界を越える音
    navigateWithBlink('library.html');
  } catch (error) {
    showAuthError('Invalid login or password');
  }
}

/**
 * 使用例:
 * // email でログイン
 * login({ login: 'user@example.com', password: 'password123' });
 *
 * // username でログイン
 * login({ login: 'user1', password: 'password123' });
 */

/**
 * サインアップ処理
 * @param {Object} userData - { email, username, password, password_confirmation }
 */
async function signup(userData) {
  try {
    const data = await apiRequest('/users', {
      method: 'POST',
      body: JSON.stringify({ user: userData })
    });

    playSound('sfx_boundary_cross.wav');
    navigateWithBlink('library.html');
  } catch (error) {
    showAuthError('Signup failed. Please check your input.');
  }
}

/**
 * 認証エラー表示（砂崩れ演出）
 * @param {string} message - エラーメッセージ
 */
function showAuthError(message) {
  const errorElement = document.getElementById('auth-error');
  errorElement.textContent = message;
  errorElement.classList.add('sand-collapse'); // 砂崩れアニメーション

  playSound('sfx_sand_crumble.wav'); // 砂の崩落音

  setTimeout(() => {
    errorElement.classList.remove('sand-collapse');
    errorElement.textContent = '';
  }, 2000);
}
```

---

## LocalStorage連携（scratchpad.js）

### 役割
- 殴り書きメモの自動保存
- 新規作成時の初期値ロード
- 保存成功時の消去

### 仕様

- **キー名**: `dream_diary_scratchpad`
- **データ形式**: `{ content: string, timestamp: number }`
- **制限**: 2,000文字
- **自動保存**: 入力ごとに即座に保存

### 実装

```javascript
const SCRATCHPAD_KEY = 'dream_diary_scratchpad';
const MAX_LENGTH = 2000;

/**
 * メモを保存
 * @param {string} content - メモ内容
 */
function saveScratchpad(content) {
  if (content.length > MAX_LENGTH) {
    content = content.substring(0, MAX_LENGTH);
  }

  const data = {
    content: content,
    timestamp: Date.now()
  };

  localStorage.setItem(SCRATCHPAD_KEY, JSON.stringify(data));
}

/**
 * メモをロード
 * @returns {string|null} メモ内容
 */
function loadScratchpad() {
  const data = localStorage.getItem(SCRATCHPAD_KEY);
  if (!data) return null;

  try {
    const parsed = JSON.parse(data);
    return parsed.content;
  } catch (error) {
    return null;
  }
}

/**
 * メモを消去
 */
function clearScratchpad() {
  localStorage.removeItem(SCRATCHPAD_KEY);
}

/**
 * 入力エリアに自動保存を設定
 * @param {HTMLElement} textarea - テキストエリア要素
 */
function setupAutoSave(textarea) {
  textarea.addEventListener('input', () => {
    saveScratchpad(textarea.value);
  });

  // 初期ロード
  const savedContent = loadScratchpad();
  if (savedContent) {
    textarea.value = savedContent;
  }
}
```

#### LocalStorage エッジケース対応
実装時に考慮すべきエッジケースと対応方法：

**① 2000文字超過時の処理**

```javascript
// saveScratchpad() で既に処理済み（substring で自動切り詰め）
// ただし、フロントエンドで警告を表示することを推奨

function saveScratchpad(content) {
  let trimmedContent = content;
  if (content.length > MAX_LENGTH) {
    trimmedContent = content.substring(0, MAX_LENGTH);
    // ⚠️ ユーザーに警告表示
    showWarning(`メモは${MAX_LENGTH}文字までです。それ以降は自動削除されました。`);
  }

  const data = {
    content: trimmedContent,
    timestamp: Date.now()
  };

  localStorage.setItem(SCRATCHPAD_KEY, JSON.stringify(data));
}
```

**② LocalStorage が満杯の場合（QuotaExceededError）**

```javascript
function saveScratchpad(content) {
  try {
    const data = {
      content: content.substring(0, MAX_LENGTH),
      timestamp: Date.now()
    };
    localStorage.setItem(SCRATCHPAD_KEY, JSON.stringify(data));
  } catch (error) {
    if (error.name === 'QuotaExceededError') {
      // LocalStorage 容量超過
      console.error('LocalStorage容量超過');
      showError('メモの保存に失敗しました。ブラウザの容量が不足しています。');
      // 古いメモは削除しない（ユーザーデータ喪失回避）
    } else {
      throw error;
    }
  }
}
```

**③ 新規作成 vs 既存編集の判定**

```javascript
/**
 * 既存編集時は LocalStorage を無視
 * @param {number|null} dreamId - 編集対象の夢日記ID（新規作成時は null）
 */
async function initializeEditor(dreamId = null) {
  if (dreamId) {
    // 既存編集：API から内容をロード
    const dream = await apiRequest(`/api/v1/dreams/${dreamId}`);
    document.getElementById('dream-content').value = dream.content;
  } else {
    // 新規作成：LocalStorage から内容をロード
    const savedContent = loadScratchpad();
    if (savedContent) {
      document.getElementById('dream-content').value = savedContent;
      console.log('Scratchpad loaded for new dream');
    }
  }
}
```

**④ ブラウザの個別ストレージ注意**
LocalStorage は **ドメイン・プロトコル・ポート** ごとに独立しています。

```javascript
// 例：以下は全て異なる LocalStorage
// http://localhost:3000  ← ブラウザ開発中の主要環境
// https://example.com     ← 本番環境
// https://staging.example.com  ← ステージング環境
// file:///path/to/index.html  ← ローカルファイル（LocalStorage不可）

// 注意：ローカルファイルで開いた HTML は LocalStorage が機能しません
// 必ず http://localhost:3000 等のサーバーで実行してください
```

**⑤ 複数タブ間での同期**
複数のブラウザタブで同時に編集した場合、LocalStorage の変更は **リアルタイム同期されません**。

```javascript
// 必要に応じて storage イベントで同期可能（ただし今回は実装不要）
window.addEventListener('storage', (event) => {
  if (event.key === SCRATCHPAD_KEY) {
    // 別のタブで LocalStorage が変更された
    console.log('Scratchpad updated in another tab');
    // 必要に応じて UI を更新
  }
});
```

**⑥ JSON パースエラー時の対応**

```javascript
function loadScratchpad() {
  const data = localStorage.getItem(SCRATCHPAD_KEY);
  if (!data) return null;

  try {
    const parsed = JSON.parse(data);
    // ✅ content フィールドが存在するか確認（データ形式検証）
    if (typeof parsed.content !== 'string') {
      throw new Error('Invalid scratchpad format');
    }
    return parsed.content;
  } catch (error) {
    console.warn('Failed to parse scratchpad:', error);
    // 破損したデータは削除（再度保存で解決）
    localStorage.removeItem(SCRATCHPAD_KEY);
    return null;
  }
}
```

**実装チェックリスト**:
- [ ] 2000文字超過時に警告表示
- [ ] QuotaExceededError をキャッチ
- [ ] 新規作成 vs 既存編集の判定ロジック実装
- [ ] JSON パース失敗時の処理
- [ ] ローカルサーバーでのテスト（http://localhost:3000）

---

## 作成・編集画面（dream_editor.js）

### 役割
- 巻物モーダルの表示・非表示
- 入力フィールド管理
- タグ入力（kuromoji.js で読み仮名生成）
- 保存処理

### kuromoji.js の使用

```javascript
let tokenizer = null;

/**
 * kuromoji.js 初期化
 */
async function initKuromoji() {
  return new Promise((resolve, reject) => {
    kuromoji.builder({ dicPath: '/path/to/dict' }).build((err, _tokenizer) => {
      if (err) {
        reject(err);
      } else {
        tokenizer = _tokenizer;
        resolve();
      }
    });
  });
}

/**
 * 漢字をひらがなに変換
 * @param {string} text - 入力テキスト
 * @returns {string} ひらがな
 */
function toHiragana(text) {
  if (!tokenizer) return text;

  // 英数字判定
  if (/^[a-zA-Z0-9]+$/.test(text)) {
    return '英数字';
  }

  try {
    const tokens = tokenizer.tokenize(text);
    return tokens.map(token => token.reading || token.surface_form)
                 .join('')
                 .replace(/[ァ-ヴ]/g, match => String.fromCharCode(match.charCodeAt(0) - 0x60)); // カタカナ→ひらがな
  } catch (error) {
    return '他'; // 生成失敗時
  }
}

/**
 * タグ追加
 * @param {Object} tag - { name, category }
 */
function addTag(tag) {
  const yomi = toHiragana(tag.name);

  // タグバッジを表示
  const badge = document.createElement('div');
  badge.className = 'tag-badge';
  badge.dataset.name = tag.name;
  badge.dataset.yomi = yomi;
  badge.dataset.category = tag.category;
  badge.innerHTML = `
    <span>${tag.name}</span>
    <button class="remove-tag">×</button>
  `;

  document.getElementById(`${tag.category}-tags-container`).appendChild(badge);
}
```

### 保存処理

```javascript
/**
 * 夢日記を保存
 * @param {boolean} isNew - 新規作成かどうか
 */
async function saveDream(isNew = true) {
  const title = document.getElementById('dream-title').value;
  const dreamedAt = document.getElementById('dreamed-at').value;
  const content = document.getElementById('dream-content').value;
  const emotionColor = document.querySelector('input[name="emotion_color"]:checked').value;

  // タグを収集
  const tagAttributes = [];
  document.querySelectorAll('.tag-badge').forEach(badge => {
    tagAttributes.push({
      name: badge.dataset.name,
      yomi: badge.dataset.yomi,
      category: badge.dataset.category
    });
  });

  const dreamData = {
    dream: {
      title,
      content,
      emotion_color: emotionColor,
      dreamed_at: dreamedAt,
      tag_attributes: tagAttributes
    }
  };

  try {
    const url = isNew ? '/api/v1/dreams' : `/api/v1/dreams/${currentDreamId}`;
    const method = isNew ? 'POST' : 'PUT';

    await apiRequest(url, {
      method,
      body: JSON.stringify(dreamData)
    });

    // LocalStorage消去（新規作成の場合のみ）
    if (isNew) {
      clearScratchpad();
    }

    // 保存演出を実行
    if (isNew) {
      playCreateAnimation();
    } else {
      playUpdateAnimation();
    }
  } catch (error) {
    alert('保存に失敗しました');
  }
}
```

### LocalStorage メモのロード（XSS 対策付き）

```javascript
/**
 * LocalStorage の殴り書きメモをロード（XSS 対策）
 * ✅ textContent/value を使用して HTML タグを無効化
 */
async function loadScratchpadMemo() {
  try {
    const memo = localStorage.getItem('scratchpad_memo');

    if (memo) {
      // ✅ 安全: value プロパティはプレーンテキストのみを設定
      // HTML タグは実行されない
      document.getElementById('dream-content').value = memo;

      // 書きかけ状態を縮小版巻物に表示
      document.querySelector('.scroll-preview').classList.add('has-memo');

      console.log('Scratchpad memo loaded (sanitized)');
    }
  } catch (error) {
    console.error('Failed to load scratchpad memo:', error);
  }
}

/**
 * 保存成功時に LocalStorage をクリア
 */
function clearScratchpad() {
  localStorage.removeItem('scratchpad_memo');
  document.querySelector('.scroll-preview').classList.remove('has-memo');
}

/**
 * ページロード時に初期化
 */
document.addEventListener('DOMContentLoaded', async () => {
  await initKuromoji();
  await loadScratchpadMemo(); // ✅ XSS 対策済みでロード
});
```

### XSS 対策の説明
**このコードが安全な理由**:
1. **JavaScript 側**:
   - `textarea.value` プロパティを使用
   - `innerHTML` ではなく `value` なので HTML タグは実行されない
   - LocalStorage から取得したデータを直接 DOM に挿入しない
2. **Rails 側**（保存時に自動実行）:
   - `before_save :sanitize_content` で HTML タグを除去
   - プレーンテキストのみを DB に保存
3. **JSON レスポンス**:
   - Rails は JSON で自動的に HTML エスケープ
   - `<` は `\u003c` に変換される

**流れ**:
```
LocalStorage (悪意あるデータ)
     ↓
JS: textarea.value で読み込み（タグ無効化）
     ↓
Rails: sanitize で HTML 除去
     ↓
DB: プレーンテキストのみ保存
     ↓
レスポンス: JSON で HTML エスケープ
```

---

## 一覧画面（dream_list.js）

### 役割
- 本棚UI（背表紙パーツ配置）
- 背表紙ホバー演出
- ページネーション
- 検索結果表示

### 実装

```javascript
/**
 * 夢日記一覧を取得して表示
 * @param {number} page - ページ番号
 */
async function loadDreams(page = 1) {
  try {
    const data = await apiRequest(`/api/v1/dreams?page=${page}`);
    renderBookshelf(data.dreams);
    renderPagination(data.pagination);
  } catch (error) {
    console.error('Failed to load dreams:', error);
  }
}

/**
 * 本棚に背表紙を配置
 * @param {Array} dreams - 夢日記の配列
 */
function renderBookshelf(dreams) {
  const container = document.getElementById('book-spines-container');
  container.innerHTML = '';

  dreams.forEach(dream => {
    const spine = createBookSpine(dream);
    container.appendChild(spine);
  });
}

/**
 * 背表紙パーツを作成
 * @param {Object} dream - 夢日記データ
 * @returns {HTMLElement} 背表紙要素
 */
function createBookSpine(dream) {
  const spine = document.createElement('div');
  spine.className = 'book-spine';
  spine.dataset.id = dream.id;
  spine.dataset.title = dream.title;
  spine.style.backgroundColor = getEmotionColor(dream.emotion_color);

  // ホバー時にタイトル表示
  spine.addEventListener('mouseenter', () => {
    showFloatingTitle(spine, dream.title);
  });

  spine.addEventListener('mouseleave', () => {
    hideFloatingTitle();
  });

  // クリックで詳細モーダル
  spine.addEventListener('click', () => {
    playSound('sfx_ui_confirm.wav');
    openDetailModal(dream.id);
  });

  return spine;
}

/**
 * 感情彩色をCSS変数から取得
 * @param {string} emotionColor - 感情彩色（peace/chaos/fear/elation）
 * @returns {string} CSS color
 */
function getEmotionColor(emotionColor) {
  const colors = {
    peace: 'var(--color-peace)',
    chaos: 'var(--color-chaos)',
    fear: 'var(--color-fear)',
    elation: 'var(--color-elation)'
  };
  return colors[emotionColor] || colors.peace;
}
```

---

## 詳細表示・削除（dream_detail.js）

### 役割
- 見開き本モーダル表示
- 編集トリガー（羽ペン＋ナイフ）
- 削除演出（忘却の儀式）

### 実装

```javascript
/**
 * 詳細モーダルを開く
 * @param {number} dreamId - 夢日記ID
 */
async function openDetailModal(dreamId) {
  closeEyes(async () => {
    try {
      const dream = await apiRequest(`/api/v1/dreams/${dreamId}`);

      // 見開き本に内容を表示
      document.getElementById('left-page').innerHTML = formatLeftPage(dream);
      document.getElementById('right-page').innerHTML = formatRightPage(dream);

      // モーダル表示
      document.getElementById('detail-modal-overlay').classList.add('active');

      openEyes();
    } catch (error) {
      console.error('Failed to load dream:', error);
    }
  });
}

/**
 * 削除処理（忘却の儀式）
 * @param {number} dreamId - 夢日記ID
 */
async function deleteDream(dreamId) {
  // 砂時計回転アニメーション
  const hourglassBtn = document.getElementById('detail-delete-button');
  hourglassBtn.classList.add('rotating');
  playSound('sfx_hourglass_rotate.wav');

  // インク滲み演出
  const leftPage = document.getElementById('left-page');
  const rightPage = document.getElementById('right-page');
  leftPage.classList.add('ink-fade');
  rightPage.classList.add('ink-fade');
  playSound('sfx_ink_dissipate.wav');

  setTimeout(async () => {
    try {
      await apiRequest(`/api/v1/dreams/${dreamId}`, { method: 'DELETE' });

      // 本が閉じる
      playSound('sfx_book_close_heavy.wav');

      // モーダル閉じる
      document.getElementById('detail-modal-overlay').classList.remove('active');

      // 一覧画面で背表紙を削除（スライドアニメーション）
      removeBookSpine(dreamId);
    } catch (error) {
      alert('削除に失敗しました');
    }
  }, 1500);
}
```

### ページネーション（BookReader クラス）

```javascript
/**
 * 本の見開きページネーション
 */
class BookReader {
  constructor(dreamContent) {
    this.content = dreamContent;
    this.charsPerPage = 500; // 1ページあたりの文字数
    this.pages = this.splitPages();
    this.currentPage = 0;
  }

  /**
   * コンテンツを固定文字数で分割
   */
  splitPages() {
    const regex = new RegExp(`.{1,${this.charsPerPage}}`, 'g');
    return this.content.match(regex) || [''];
  }

  /**
   * 現在のページ内容を取得
   */
  getCurrentPageContent() {
    return this.pages[this.currentPage] || '';
  }

  /**
   * ページ番号を取得（"1/5"形式）
   */
  getPageNumber() {
    return `${this.currentPage + 1}/${this.pages.length}`;
  }

  /**
   * 次ページへ移動（3D回転演出付き）
   */
  async nextPage() {
    if (this.currentPage >= this.pages.length - 1) return;

    await this.flipPage('next');
    this.currentPage++;
    this.render();
  }

  /**
   * 前ページへ移動（3D回転演出付き）
   */
  async prevPage() {
    if (this.currentPage <= 0) return;

    await this.flipPage('prev');
    this.currentPage--;
    this.render();
  }

  /**
   * 3D回転めくり演出
   * @param {string} direction - 'next' または 'prev'
   */
  async flipPage(direction) {
    const pageEl = document.querySelector('.right-page');

    if (direction === 'next') {
      pageEl.classList.add('flip-out-forward');
      playSound('sfx_page_turn.wav');
    } else {
      pageEl.classList.add('flip-out-backward');
      playSound('sfx_page_turn.wav');
    }

    // 回転中（400ms）にページ内容を更新
    await new Promise(r => setTimeout(r, 400));

    // クラスをリセットして次のアニメーションに備える
    pageEl.classList.remove('flip-out-forward', 'flip-out-backward');
  }

  /**
   * ページ表示を更新
   */
  render() {
    const pageContent = this.getCurrentPageContent();
    document.querySelector('.right-page-content').textContent = pageContent;
    document.querySelector('.page-number').textContent = this.getPageNumber();
  }
}

/**
 * 詳細モーダルを開く（ページネーション対応版）
 * @param {number} dreamId - 夢日記ID
 */
async function openDetailModal(dreamId) {
  closeEyes(async () => {
    try {
      const dream = await apiRequest(`/api/v1/dreams/${dreamId}`);

      // BookReaderインスタンスを作成
      window.bookReader = new BookReader(dream.content);

      // 見開き本にメタデータと最初のページを表示
      document.getElementById('dream-title').textContent = dream.title;
      document.getElementById('dream-date').textContent = formatDate(dream.dreamed_at);
      document.querySelector('.right-page-content').textContent =
        window.bookReader.getCurrentPageContent();
      document.querySelector('.page-number').textContent =
        window.bookReader.getPageNumber();

      // モーダル表示
      document.getElementById('detail-modal-overlay').classList.add('active');

      openEyes();
    } catch (error) {
      console.error('Failed to load dream:', error);
    }
  });
}
```

### HTML構造（詳細モーダル）

```html
<div id="detail-modal-overlay" class="modal-overlay">
  <div class="book-detail-container">
    <!-- 見開き本 -->
    <div class="book-open-frame">
      <!-- 左ページ（固定 - メタデータ） -->
      <div class="page left-page">
        <div class="page-frame">
          <h2 id="dream-title"></h2>
          <p id="dream-date"></p>
          <p id="dream-tags"></p>
        </div>
      </div>

      <!-- 右ページ（スクロール - 本文） -->
      <div class="page right-page" onclick="bookReader.nextPage()">
        <div class="page-frame">
          <p class="right-page-content"></p>
        </div>
      </div>
    </div>

    <!-- ページネーション -->
    <div class="pagination">
      <button onclick="bookReader.prevPage()" class="page-nav-btn prev">
        ← 前ページ
      </button>
      <span class="page-number">1/1</span>
      <button onclick="bookReader.nextPage()" class="page-nav-btn next">
        次ページ →
      </button>
    </div>

    <!-- 操作ボタン -->
    <button id="detail-edit-button" onclick="editDream()">
      修正（羽ペン＋ナイフ）
    </button>
    <button id="detail-delete-button" onclick="deleteDream()">
      忘却（砂時計）
    </button>
  </div>
</div>
```

---

## タグサジェスト（tag_suggest.js）

### 役割
- オートコンプリートUI
- デバウンス処理
- タグ選択

### 実装

```javascript
let debounceTimer = null;

/**
 * タグサジェスト（デバウンス付き）
 * @param {string} query - 検索文字列
 * @param {string} category - カテゴリ（person/place）
 */
function suggestTags(query, category) {
  clearTimeout(debounceTimer);

  debounceTimer = setTimeout(async () => {
    if (query.length < 1) {
      hideSuggestions();
      return;
    }

    try {
      const data = await apiRequest(`/api/v1/tags/suggest?query=${query}&category=${category}`);
      showSuggestions(data.suggestions);
    } catch (error) {
      console.error('Tag suggestion failed:', error);
    }
  }, 300); // 300msのデバウンス
}

/**
 * サジェストリストを表示
 * @param {Array} suggestions - サジェストタグ配列
 */
function showSuggestions(suggestions) {
  const container = document.getElementById('tag-suggestions');
  container.innerHTML = '';

  suggestions.forEach(tag => {
    const item = document.createElement('div');
    item.className = 'suggestion-item';
    item.textContent = tag.name;
    item.addEventListener('click', () => {
      selectTag(tag);
      hideSuggestions();
    });
    container.appendChild(item);
  });

  container.style.display = 'block';
}
```

---

## 検索（index_box.js）

### 役割
- 索引箱モーダル表示
- タグカード一覧（五十音順）
- 2つの検索入力欄
- AND検索実行

### 実装

```javascript
/**
 * 索引箱を開く
 */
async function openIndexBox() {
  closeEyes(async () => {
    try {
      const data = await apiRequest('/api/v1/tags');
      renderTagCards(data.tags);

      document.getElementById('index-card-modal').classList.add('visible');
      openEyes();
    } catch (error) {
      console.error('Failed to load tags:', error);
    }
  });
}

/**
 * タグカードを五十音順に表示
 * @param {Array} tags - タグ配列
 */
function renderTagCards(tags) {
  const container = document.getElementById('card-list');
  container.innerHTML = '';

  // yomi_index でグループ化
  const grouped = groupByYomiIndex(tags);

  Object.keys(grouped).forEach(yomiIndex => {
    const header = document.createElement('div');
    header.className = 'yomi-index-header';
    header.textContent = yomiIndex;
    container.appendChild(header);

    grouped[yomiIndex].forEach(tag => {
      const card = createTagCard(tag);
      container.appendChild(card);
    });
  });
}

/**
 * AND検索実行
 */
async function executeSearch() {
  const keywords = document.getElementById('body-search-input').value;
  const selectedTags = getSelectedTags();

  const tagIds = selectedTags.map(tag => tag.id).join(',');
  const url = `/api/v1/dreams/search?keywords=${keywords}&tag_ids=${tagIds}`;

  try {
    const data = await apiRequest(url);

    // 索引箱を閉じて一覧画面へ遷移
    document.getElementById('index-card-modal').classList.remove('visible');
    renderBookshelf(data.dreams);
  } catch (error) {
    console.error('Search failed:', error);
  }
}
```

## タグ削除（Day 4 Task 2 詳細）

### UI 要素
- 各タグカード（img_tag_card_base.png）の右下隅に「破れた紙片」アイコン（img_tag_delete.png）を配置
- ホバー時: カーソルが変化、カード全体が微かに発光

### 実装

```javascript
/**
 * タグカード作成（削除ボタン付き）
 * @param {Object} tag - タグオブジェクト（Rails API から受け取った JSON）
 * @returns {HTMLElement} タグカード要素
 */
function createTagCard(tag) {
  const card = document.createElement('div');
  card.className = 'tag-card';
  card.dataset.id = tag.id;

  // カード内容
  const cardContent = document.createElement('div');
  cardContent.className = 'tag-card-content';
  cardContent.textContent = tag.name;
  card.appendChild(cardContent);

  // 削除ボタン（破れた紙片）
  const deleteBtn = document.createElement('button');
  deleteBtn.className = 'tag-delete-btn';
  deleteBtn.style.backgroundImage = "url('/assets/img_tag_delete.png')";
  deleteBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    deleteTag(tag.id);
  });
  card.appendChild(deleteBtn);

  return card;
}

/**
 * タグ削除
 * @param {number} tagId - 削除するタグのID
 */
async function deleteTag(tagId) {
  try {
    // DELETE リクエスト
    await apiRequest(`/api/v1/tags/${tagId}`, {
      method: 'DELETE'
    });

    // アニメーション実行
    const cardElement = document.querySelector(`.tag-card[data-id="${tagId}"]`);
    if (cardElement) {
      cardElement.classList.add('deleting');

      // アニメーション完了後、DOM から削除
      setTimeout(() => {
        cardElement.remove();
      }, 600); // crumble-and-fade の所要時間
    }

    console.log(`Tag ${tagId} deleted successfully`);
  } catch (error) {
    console.error('Failed to delete tag:', error);
    showError('タグの削除に失敗しました');
  }
}
```

### 参照
- **アニメーション**: `05_animations.md` § タグ削除演出（風化して消滅）
- **API**: `03_api.md` § DELETE /api/v1/tags/:id（タグ削除）

---

## コールドスタート対応（Day 3 Task 1-2 詳細）

### 本棚が空の場合

**条件**: `dreams.length === 1 かつ title === '書斎の使い方'`

### 表示フロー

**第1段階: 本棚への視覚的ガイダンス**
- 書斎画面ロード時、本棚ユニットに以下のエフェクトを適用:
  - **発光**: `filter: brightness(1.2) drop-shadow(0 0 15px rgba(255, 215, 0, 0.6))`
  - **振動**: `animation: bookshelf-guide 2s ease-in-out infinite` で軽く振わせる
- チュートリアル本（背表紙）が本棚に 1冊配置

**第2段階: 操作開始への誘導**
- ユーザーがチュートリアル本を読み終えた後
- 机の上の巻物が発光エフェクト（brightness 増加）で点灯

**操作フロー**:
- ユーザーが巻物をクリック
- 新規作成モーダルが開く
- 新しい夢の記録を開始

### 実装例

**JavaScript**:
```javascript
// 初期表示時のチェック
function checkColdStart() {
  if (dreams.length === 1 && dreams[0].title === '書斎の使い方') {
    // 本棚を発光・振動させる
    const bookshelf = document.querySelector('.bookshelf');
    bookshelf.classList.add('cold-start-guide');

    // チュートリアル本をハイライト
    highlightTutorialBook(dreams[0]);

    // ユーザーが本を読み終えたら（click or読了時間経過）
    onTutorialComplete(() => {
      // 巻物を発光させる
      const scroll = document.querySelector('.scroll-ui');
      scroll.classList.add('highlight');
    });
  }
}
```

**CSS**:
```css
/* 本棚の発光・振動 */
.bookshelf.cold-start-guide {
  animation: bookshelf-guide 2s ease-in-out infinite;
  filter: brightness(1.2) drop-shadow(0 0 15px rgba(255, 215, 0, 0.6));
}

@keyframes bookshelf-guide {
  0%, 100% { transform: translateX(0); }
  25% { transform: translateX(-2px); }
  75% { transform: translateX(2px); }
}

/* 巻物の発光 */
.scroll-ui.highlight {
  animation: scroll-glow 1.5s ease-in-out infinite;
  filter: brightness(1.3) drop-shadow(0 0 10px rgba(255, 215, 0, 0.8));
}

@keyframes scroll-glow {
  0%, 100% { filter: brightness(1.3); }
  50% { filter: brightness(1.5); }
}
```

### 参照
- **初期データ**: `02_database.md` § 初期データ（Seed Data）

---

このファイルは、フロントエンド実装の完全ガイドです。
Day 3-5（UIプロトタイプ統合、CRUD機能統合、検索機能）で参照してください。
