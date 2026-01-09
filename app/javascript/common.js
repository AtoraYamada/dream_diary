// common.js - Global JavaScript functions and utilities

/**
 * 閉眼アニメーションのみを実行（ページ遷移用）
 * @param {Function} callback - 閉眼完了後に実行する処理（通常はページ遷移）
 */
function closeEyes(callback) {
    const blinkOverlay = document.createElement('div');
    blinkOverlay.classList.add('blink-overlay');
    document.body.appendChild(blinkOverlay);

    // Asset: sfx_blink.wav (瞬きの音) - plays when eyes close
    playSound('sfx_blink.wav');

    // Force browser reflow to ensure initial state is rendered
    blinkOverlay.offsetHeight; // Trigger reflow

    // Step 1: Close eyes (上下から中央へ)
    requestAnimationFrame(() => {
        blinkOverlay.classList.add('closing');
    });

    // After closing animation completes (0.3s)
    setTimeout(() => {
        // Execute callback (e.g., navigate)
        if (callback && typeof callback === 'function') {
            callback();
        }
    }, 300); // Corresponds to 0.3s closing transition
}

/**
 * 開眼アニメーションのみを実行（ページ読み込み後用）
 */
function openEyes() {
    // チラつき防止：will-open-eyesクラスがあれば削除
    // (awakening演出時など、CSS暗転を開眼と同時に解除)
    if (document.documentElement.classList.contains('will-open-eyes')) {
        document.documentElement.classList.remove('will-open-eyes');
    }

    // 既存のblink overlayを削除（重複を防ぐ）
    const existingOverlays = document.querySelectorAll('.blink-overlay');
    existingOverlays.forEach(overlay => overlay.remove());

    const blinkOverlay = document.createElement('div');
    blinkOverlay.classList.add('blink-overlay', 'closing'); // Start in closed state
    document.body.appendChild(blinkOverlay);

    // Force browser reflow
    blinkOverlay.offsetHeight;

    // Step 1: Open eyes (中央から上下へ)
    requestAnimationFrame(() => {
        blinkOverlay.classList.remove('closing');
        blinkOverlay.classList.add('opening');
    });

    // After opening animation completes (0.5s), remove the overlay
    setTimeout(() => {
        blinkOverlay.remove();
    }, 500); // Corresponds to 0.5s opening transition
}

/**
 * 同一ページ内での瞬き演出（ページ遷移なし）
 * @param {Function} callback - 目を閉じている間に実行する処理
 */
function initiateBlinkTransition(callback) {
    closeEyes(() => {
        // Execute callback while eyes are closed
        if (callback && typeof callback === 'function') {
            callback();
        }

        // Wait briefly, then open eyes
        setTimeout(() => {
            openEyes();
        }, 200);
    });
}

/**
 * Placeholder for playing sound effects.
 * @param {string} sfxFileName - The filename of the sound effect (e.g., 'sfx_blink.wav').
 * Refer to dream_diary_asset_list.md for SFX details.
 */
function playSound(sfxFileName) {
    // In a real implementation, you would load and play audio here.
    // For prototype, just log to console.
}

/**
 * Simulates saving data to LocalStorage.
 * @param {string} key - The key for LocalStorage.
 * @param {any} data - The data to save.
 */
function saveToLocalStorage(key, data) {
    try {
        localStorage.setItem(key, JSON.stringify(data));
    } catch (e) {
        console.error(`[LocalStorage] Error saving data for key: ${key}`, e);
    }
}

/**
 * Simulates loading data from LocalStorage.
 * @param {string} key - The key for LocalStorage.
 * @returns {any | null} - The loaded data or null if not found/error.
 */
function loadFromLocalStorage(key) {
    try {
        const data = localStorage.getItem(key);
        return data ? JSON.parse(data) : null;
    } catch (e) {
        console.error(`[LocalStorage] Error loading data for key: ${key}`, e);
        return null;
    }
}

/**
 * Simulates removing data from LocalStorage.
 * @param {string} key - The key for LocalStorage.
 */
function removeFromLocalStorage(key) {
    try {
        localStorage.removeItem(key);
    } catch (e) {
        console.error(`[LocalStorage] Error removing data for key: ${key}`, e);
    }
}

/**
 * Navigates to a new page with a blink transition.
 * @param {string} url - The URL of the page to navigate to.
 * @param {string} sfx - Optional sound effect to play during transition (e.g., 'sfx_door_open_heavy.wav').
 */
function navigateWithBlink(url, sfx = null) {
    if (sfx) {
        playSound(sfx);
    }

    closeEyes(() => {
        // Add blink parameter to URL for opening eyes on next page
        const separator = url.includes('?') ? '&' : '?';
        window.location.href = url + separator + 'blink=open';
    });
}

/**
 * ページ読み込み時に開眼アニメーションを実行するかチェック
 * 各HTMLページのDOMContentLoadedで呼び出す
 *
 * 注: チラつき防止のため、head内でhtml.will-open-eyesクラスを追加済み。
 * この関数でクラスを削除して開眼アニメーション実行。
 */
function checkAndOpenEyes() {
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.get('blink') === 'open') {
        // html.will-open-eyesクラスがある場合、開眼アニメーションを実行
        const hasWillOpenEyes = document.documentElement.classList.contains('will-open-eyes');
        if (hasWillOpenEyes) {
            // 開眼アニメーション用のオーバーレイを作成（初期状態: 閉じている）
            const blinkOverlay = document.createElement('div');
            blinkOverlay.classList.add('blink-overlay', 'closing');
            document.body.appendChild(blinkOverlay);

            // Force browser reflow
            blinkOverlay.offsetHeight;

            // 次のフレームで開眼アニメーション開始
            requestAnimationFrame(() => {
                // will-open-eyesクラスを削除（開眼アニメーション開始と同時にCSS暗転を解除）
                document.documentElement.classList.remove('will-open-eyes');

                blinkOverlay.classList.remove('closing');
                blinkOverlay.classList.add('opening');

                // アニメーション完了後にオーバーレイを削除
                setTimeout(() => {
                    blinkOverlay.remove();
                }, 500); // 0.5s opening transition
            });
        }

        // Remove parameter from URL without reloading
        urlParams.delete('blink');
        const newUrl = window.location.pathname + (urlParams.toString() ? '?' + urlParams.toString() : '');
        window.history.replaceState({}, document.title, newUrl);
    }
}

/**
 * ログアウト専用の演出（目覚めの儀式）
 * 要件 3.4.1:
 * 1. 第1の瞬き（閉眼）
 * 2. 覚醒の兆候（開眼）→ トップページの森の画像がぼかしで表示
 * 3. 第2の瞬き（再閉眼・開眼）
 * 4. 完全な覚醒 → 通常のトップページ
 */
function logoutWithAwakeningEffect() {
    // playSound('sfx_mirror_ripple.wav'); // Asset: 鏡の波紋音

    // 第1の瞬き
    closeEyes(() => {
        // index.htmlへ遷移して、ぼかし状態で表示
        window.location.href = '/?awakening=true';
    });
}

// Function to convert Katakana to Hiragana (from index_card_layout.html for search/filter)
function toHiragana(str) {
    return str.replace(/[\u30a1-\u30f6]/g, function(match) {
        return String.fromCharCode(match.charCodeAt(0) - 0x60);
    });
}

// ES Module exports
export {
    closeEyes,
    openEyes,
    initiateBlinkTransition,
    playSound,
    saveToLocalStorage,
    loadFromLocalStorage,
    removeFromLocalStorage,
    navigateWithBlink,
    checkAndOpenEyes,
    logoutWithAwakeningEffect,
    toHiragana
};

// Export functions to global scope for use in inline scripts (for backward compatibility)
window.closeEyes = closeEyes;
window.openEyes = openEyes;
window.initiateBlinkTransition = initiateBlinkTransition;
window.playSound = playSound;
window.saveToLocalStorage = saveToLocalStorage;
window.loadFromLocalStorage = loadFromLocalStorage;
window.removeFromLocalStorage = removeFromLocalStorage;
window.navigateWithBlink = navigateWithBlink;
window.checkAndOpenEyes = checkAndOpenEyes;
window.logoutWithAwakeningEffect = logoutWithAwakeningEffect;
window.toHiragana = toHiragana;
