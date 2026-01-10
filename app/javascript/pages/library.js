// library.js - Library page (main hub: bookshelf, window, desk scroll, mirror)

import { openScrollModal, closeScrollModal, initializeInkBottleSelection } from '../modals/scroll_modal.js';
import { checkAndOpenEyes, navigateWithBlink, logoutWithAwakeningEffect, playSound, loadFromLocalStorage } from '../common.js';

/**
 * 本棚の表示を夢の数に応じて更新（書斎画面用）
 * @param {number} dreamCount - 夢の数
 */
function updateBookshelfDisplay(dreamCount) {
    const bookshelf = document.getElementById('bookshelf');
    if (!bookshelf) {
        console.warn('[updateBookshelfDisplay] bookshelf element not found');
        return;
    }

    // 既存のクラスを削除
    bookshelf.classList.remove(
        'bookshelf-empty',
        'bookshelf-small',
        'bookshelf-medium',
        'bookshelf-large'
    );

    // 夢の数に応じてクラスを追加
    if (dreamCount === 0) {
        bookshelf.classList.add('bookshelf-empty');
    } else if (dreamCount <= 3) {
        bookshelf.classList.add('bookshelf-small');
    } else if (dreamCount <= 7) {
        bookshelf.classList.add('bookshelf-medium');
    } else {
        bookshelf.classList.add('bookshelf-large');
    }
}

/**
 * 縮小版巻物の表示をLocalStorageのメモ有無に応じて更新
 */
function updateScrollMiniDisplay() {
    const deskScrollMini = document.getElementById('desk-scroll-mini');
    if (!deskScrollMini) {
        console.warn('[updateScrollMiniDisplay] desk-scroll-mini element not found');
        return;
    }

    // LocalStorageからメモを取得
    const scratchpadData = loadFromLocalStorage('dream_diary_scratchpad');
    const hasMemo = scratchpadData && scratchpadData.content && scratchpadData.content.trim() !== '';

    // 既存のクラスを削除
    deskScrollMini.classList.remove('has-memo', 'no-memo');

    // メモ有無に応じてクラスを追加
    if (hasMemo) {
        deskScrollMini.classList.add('has-memo');
    } else {
        deskScrollMini.classList.add('no-memo');
    }
}

// グローバル関数: 作成編集モーダルを開く
function openCreateEditModal(isEdit = false) {
    const deskScrollMini = document.getElementById('desk-scroll-mini');
    const deskScrollText = document.getElementById('desk-scroll-text');

    openScrollModal({
        onBeforeOpen: () => {
            // 瞬き中に縮小版巻物とテキストを非表示にする（机の上の巻物が手に取られた感覚を演出）
            if (deskScrollMini) {
                deskScrollMini.classList.add('hidden');
            }
            if (deskScrollText) {
                deskScrollText.classList.add('hidden');
            }
        }
    });
}

// グローバル関数: 作成編集モーダルを閉じる
function closeCreateEditModal() {
    const deskScrollMini = document.getElementById('desk-scroll-mini');
    const deskScrollText = document.getElementById('desk-scroll-text');

    closeScrollModal({
        duringBlink: () => {
            // フォーム入力内容をクリア（保存時のリセット）
            const dreamTitleInput = document.getElementById('dream-title-input');
            const dreamTextarea = document.getElementById('dream-textarea');
            const characterTagInput = document.getElementById('character-tag-input');
            const locationTagInput = document.getElementById('location-tag-input');
            const characterTagsDisplay = document.getElementById('character-tags-display');
            const locationTagsDisplay = document.getElementById('location-tags-display');

            if (dreamTitleInput) dreamTitleInput.value = '';
            if (dreamTextarea) dreamTextarea.value = '';
            if (characterTagInput) characterTagInput.value = '';
            if (locationTagInput) locationTagInput.value = '';
            if (characterTagsDisplay) characterTagsDisplay.innerHTML = '';
            if (locationTagsDisplay) locationTagsDisplay.innerHTML = '';
        },
        afterBlink: () => {
            // 縮小版巻物とテキストを瞬きのタイミングで確実に再表示
            setTimeout(() => {
                if (deskScrollMini) {
                    deskScrollMini.classList.remove('hidden');
                }
                if (deskScrollText) {
                    deskScrollText.classList.remove('hidden');
                }
            }, 100); // 瞬き明けのアニメーション完了後に表示
        }
    });
}

// Export global functions
window.openCreateEditModal = openCreateEditModal;
window.closeCreateEditModal = closeCreateEditModal;

// Check for opening eyes animation (from page transition)
checkAndOpenEyes();

const deskScroll = document.getElementById('desk-scroll');
const bookshelf = document.getElementById('bookshelf');
const windowElement = document.getElementById('window');
const mirror = document.getElementById('mirror');
const dreamFloodOverlay = document.getElementById('dream-flood-overlay');
const createEditModalOverlay = document.getElementById('create-edit-modal-overlay');

// Read paths from data attributes
const listPath = document.body.dataset.listPath;

// Play ambient sound (placeholder)
// Commented out: playSound('sfx_library_ambience.mp3'); // Asset: 書斎の環境音 (loop)

// Desk/Scroll click (夢を編む機能への遷移 - モーダル方式)
deskScroll.addEventListener('click', () => {
    playSound('sfx_ui_confirm.wav'); // Asset: 選択・決定音
    openCreateEditModal(false); // false = 新規作成モード
});

// Create/Edit Modal: 外クリックで閉じる
createEditModalOverlay.addEventListener('click', (e) => {
    if (e.target === createEditModalOverlay) {
        closeCreateEditModal();
        playSound('sfx_ui_confirm.wav'); // Asset: 選択・決定音
    }
});

// Bookshelf click (記憶の目録機能への遷移)
bookshelf.addEventListener('click', () => {
    // Asset: ズームイン/アウト音 (sfx_zoom_in_out.wav)
    // 書斎から一覧へ（別ページ遷移）
    navigateWithBlink(listPath);
});

// Window click (夢の氾濫ギミックの発動)
windowElement.addEventListener('click', () => {
    playSound('sfx_glass_warp.wav'); // Asset: ガラスの歪む音
    dreamFloodOverlay.classList.add('active');
    // Auto-hide after 1 minute, or click outside to close
    setTimeout(() => {
        if (dreamFloodOverlay.classList.contains('active')) {
            dreamFloodOverlay.classList.remove('active');
        }
    }, 60000); // 1 minute
});

// Click outside dream flood text to close
dreamFloodOverlay.addEventListener('click', (event) => {
    if (event.target === dreamFloodOverlay) { // Only if clicking the overlay itself, not the text
        dreamFloodOverlay.classList.remove('active');
        playSound('sfx_ui_confirm.wav'); // Asset: 選択・決定音 (オーバーレイを閉じる確認音)
    }
});

// Save Bookmark click (Save/Close create-edit modal - 定着の儀式)
const saveBookmark = document.getElementById('library-save-bookmark');
saveBookmark.addEventListener('click', () => {
    // 栞の発光演出（保存の儀式を視覚的に表現）
    saveBookmark.classList.add('glow');
    playSound('sfx_ui_confirm.wav'); // Asset: 選択・決定音

    // 発光アニメーション完了後にモーダルを閉じる
    setTimeout(() => {
        closeCreateEditModal();
        // playSound('sfx_scroll_roll_up.wav'); // Asset: 巻物の収束音 (closeCreateEditModal内で実行)

        // アニメーション終了後にglowクラスを削除
        setTimeout(() => {
            saveBookmark.classList.remove('glow');
        }, 600); // closeCreateEditModalの処理時間に合わせる
    }, 300); // bookmark-glowアニメーションの時間
});

/* ============================================================
 * 段階2：本の実体化アニメーション（将来実装：アセット到着時に有効化）
 * ============================================================
 *
 * Assets Required:
 * - img_book_closed_front.png (本：正面（閉）)
 * - img_book_half_open.png (本：半分開きかけ)
 *
 * Animation Sequence (Timing: 栞の発光完了後 0.3s に開始):
 * 1. 巻物の中間部分が高速で縮小（Height: 0）
 *    - Sound: sfx_scroll_roll_up.wav（巻物の収束音）
 *
 * 2. 本のパラパラ漫画アニメーション（モーダル内中央）
 *    - img_book_half_open.png を表示（0.1s〜0.2s）
 *    - img_book_closed_front.png に切り替わる
 *    - Sound: sfx_book_close.wav（重厚な閉本音）を同期
 *
 * 3. 本が飛び去る演出
 *    - 本がモーダル背後の本棚へ縮小しながら飛んでいく
 *    - モーダルが閉じる
 *    - 書斎のぼかしが解除される
 *
 * 4. 本棚のテクスチャ更新
 *    - 蔵書数に応じて段階（小/中/大）へ更新
 *
 * Note: テキスト内容は表示しない（本のビジュアルアニメーションのみ）
 * Deferred: Assets未到着のため、段階1（発光演出）のみ実装
 * Status: 詳細な仕様で実装準備完了、アセット到着時に実装可能
 * ============================================================ */

// Ink bottle click (感情選択 - scroll-middleの背景色変更)
initializeInkBottleSelection();

// Mirror click (Logout - 目覚める儀式)
mirror.addEventListener('click', () => {
    // Logout sequence with awakening effect (3.4.1)
    logoutWithAwakeningEffect();
});

// library.htmlが読み込まれた時にのみ実行
if (document.getElementById('bookshelf')) {
    const dummyDreamCount = 4; // 仮の夢の数（0, 1-3, 4-7, 8以上で本棚画像が変わる）
    updateBookshelfDisplay(dummyDreamCount);
}

// library.htmlが読み込まれた時にのみ実行
if (document.getElementById('desk-scroll-mini')) {
    updateScrollMiniDisplay();
}
