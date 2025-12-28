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
    console.log(`[SFX] Playing sound: ${sfxFileName}`);
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
        console.log(`[LocalStorage] Data saved for key: ${key}`);
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
        console.log(`[LocalStorage] Data removed for key: ${key}`);
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
        if (document.documentElement.classList.contains('will-open-eyes')) {
            // 開眼アニメーション用のオーバーレイを作成（初期状態: 閉じている）
            const blinkOverlay = document.createElement('div');
            blinkOverlay.classList.add('blink-overlay', 'initial-closed');
            document.body.appendChild(blinkOverlay);

            // will-open-eyesクラスを削除（CSS暗転を解除）
            document.documentElement.classList.remove('will-open-eyes');

            // 次のフレームで開眼アニメーション開始
            requestAnimationFrame(() => {
                blinkOverlay.classList.remove('initial-closed');
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
        window.location.href = 'index.html?awakening=true';
    });
}

// Function to convert Katakana to Hiragana (from index_card_layout.html for search/filter)
function toHiragana(str) {
    return str.replace(/[\u30a1-\u30f6]/g, function(match) {
        return String.fromCharCode(match.charCodeAt(0) - 0x60);
    });
}

/**
 * Initializes the Index Card Modal functionality.
 * This function should be called after the modal HTML is added to the DOM.
 * It sets up event listeners for tag selection, search, reset, match, and index plate navigation.
 */
function initIndexCardModal() {
    const cardList = document.getElementById('card-list');
    const selectedTagsContainer = document.getElementById('selected-tags');
    const tagFilterInput = document.getElementById('tag-filter-input');
    const bodySearchInput = document.getElementById('body-search-input');
    const matchButton = document.getElementById('match-button');
    const resetButton = document.getElementById('reset-button');
    const indexPlateContainer = document.querySelector('.index-plate-container');

    let selectedTagNames = new Set();

    // タグ絞り込み検索 (フィルタリングロジック)
    function filterCards() {
        const rawKeyword = tagFilterInput.value;
        const normalizedKeyword = toHiragana(rawKeyword.toLowerCase());
        const cards = cardList.querySelectorAll('.tag-card');
        
        cards.forEach(card => {
            if (normalizedKeyword === '') {
                card.classList.remove('filtered-out');
                return;
            }

            const name = card.dataset.tagName;
            const yomi = card.dataset.tagYomi;

            const normalizedName = toHiragana(name.toLowerCase());
            const normalizedYomi = toHiragana(yomi.toLowerCase());

            if (normalizedName.includes(normalizedKeyword) || normalizedYomi.includes(normalizedKeyword)) {
                card.classList.remove('filtered-out');
            } else {
                card.classList.add('filtered-out');
            }
        });
    }
    
    tagFilterInput.addEventListener('keyup', filterCards);

    // Update selected tags display (UI更新ロジック)
    function updateSelectedTagsDisplay() {
        const existingBadges = selectedTagsContainer.querySelectorAll('.tag-badge');
        existingBadges.forEach(badge => badge.remove()); // Remove all except the label

        const labelSpan = selectedTagsContainer.querySelector('.label');
        if (!labelSpan) { // Add label if it doesn't exist
            const newLabel = document.createElement('span');
            newLabel.className = 'label';
            newLabel.textContent = '選択中の索引：';
            selectedTagsContainer.prepend(newLabel);
        }

        selectedTagNames.forEach(tagName => {
            const badge = document.createElement('div');
            badge.className = 'tag-badge';
            badge.textContent = tagName;
            
            const removeBtn = document.createElement('span');
            removeBtn.className = 'remove-btn';
            removeBtn.textContent = '×';
            removeBtn.onclick = (event) => {
                event.stopPropagation(); // Prevent card selection when clicking remove button
                selectedTagNames.delete(tagName);
                
                const cardToDeselect = cardList.querySelector(`.tag-card[data-tag-name="${tagName}"]`);
                if(cardToDeselect) {
                    cardToDeselect.classList.remove('selected');
                }
                
                updateSelectedTagsDisplay();
                playSound('sfx_ui_confirm.wav'); // Asset: 選択・決定音 (タグ削除)
            };
            badge.appendChild(removeBtn);
            selectedTagsContainer.appendChild(badge);
        });
    }

    // Event listener for clicking a tag card (選択/ピン留め)
    cardList.addEventListener('click', (event) => {
        if (event.target.closest('.delete-tag-icon')) { // Ignore clicks on delete icon
            return;
        }
        const card = event.target.closest('.tag-card');
        if (card && !card.classList.contains('selected')) { // Card click is for selection only
            const tagName = card.dataset.tagName;
            card.classList.add('selected');
            selectedTagNames.add(tagName);
            updateSelectedTagsDisplay();
            playSound('sfx_pin.wav'); // Asset: ピン留め音
        }
    });

    // Reset button (開架) functionality
    if (resetButton) {
        resetButton.addEventListener('click', () => {
            playSound('sfx_ui_confirm.wav'); // Asset: 選択・決定音 (全クリア)

            // モーダル外クリック時と同じ処理を使用（瞬き演出 + モーダルクローズ）
            const indexCardModal = document.getElementById('index-card-modal');
            const indexBoxTrigger = document.getElementById('index-box-trigger');
            initiateBlinkTransition(() => {
                // closeEyesのコールバック：瞬き中にリセット処理を実行
                tagFilterInput.value = '';
                bodySearchInput.value = '';
                selectedTagNames.clear();
                const allCards = cardList.querySelectorAll('.tag-card');
                allCards.forEach(card => card.classList.remove('selected', 'filtered-out'));
                updateSelectedTagsDisplay();
                filterCards();

                console.log('Closing index card modal by reset button');
                indexCardModal.classList.remove('visible');
                if (indexBoxTrigger) indexBoxTrigger.style.display = 'block'; // Show trigger when modal closes
            });
        });
    }

    // Match button (抽出) functionality
    if (matchButton) {
        matchButton.addEventListener('click', () => {
            console.log('--- 照合実行 ---');
            console.log('選択中のタグ:', Array.from(selectedTagNames));
            console.log('本文検索キーワード:', bodySearchInput.value);
            playSound('sfx_ui_confirm.wav'); // Asset: 選択・決定音 (検索実行)

            // モーダル外クリック時と同じ処理を使用
            const indexCardModal = document.getElementById('index-card-modal');
            const indexBoxTrigger = document.getElementById('index-box-trigger');
            initiateBlinkTransition(() => {
                console.log('Closing index card modal by match button');
                indexCardModal.classList.remove('visible');
                if (indexBoxTrigger) indexBoxTrigger.style.display = 'block'; // Show trigger when modal closes
            });
        });
    }

    // Delete icon event listener (タグの破棄アニメーションと削除)
    cardList.querySelectorAll('.tag-card').forEach(tagCard => { // Attach to each tag-card for its delete icon
        const deleteIcon = tagCard.querySelector('.delete-tag-icon');
        if (deleteIcon) {
            deleteIcon.addEventListener('click', (event) => {
                event.stopPropagation(); // Prevent card selection when clicking delete icon
                const tagName = tagCard.dataset.tagName;
                
                tagCard.classList.add('is-deleting'); // Trigger deletion animation
                playSound('sfx_paper_crumble.wav'); // Asset: 紙片の破棄音 (例: tag_card_deletion.mp3)
                
                tagCard.addEventListener('animationend', () => {
                    tagCard.remove();
                    selectedTagNames.delete(tagName); // Remove from selected tags if it was there
                    updateSelectedTagsDisplay();
                    // No additional sound here as paper_crumble covers the "vanishing" effect
                }, { once: true });
            });
        }
    });

    // Index plate jump functionality (文字で絞り込み)
    if (indexPlateContainer) {
        indexPlateContainer.addEventListener('click', (event) => {
            const indexPlate = event.target.closest('.index-plate');
            if (indexPlate) {
                const char = indexPlate.textContent.toLowerCase();
                const cards = cardList.querySelectorAll('.tag-card');
                let targetCard = null;

                // Find the first card starting with the selected character (or its yomi)
                for (let i = 0; i < cards.length; i++) {
                    const tagName = toHiragana(cards[i].dataset.tagName.toLowerCase());
                    const tagYomi = toHiragana(cards[i].dataset.tagYomi.toLowerCase());
                    
                    if ((tagName.startsWith(char) || tagYomi.startsWith(char)) && !cards[i].classList.contains('filtered-out')) {
                        targetCard = cards[i];
                        break;
                    }
                }

                if (targetCard) {
                    cardList.scrollTo({
                        top: targetCard.offsetTop - cardList.offsetTop,
                        behavior: 'smooth'
                    });
                    playSound('sfx_tag_card_flip.wav'); // Asset: 索引カードをめくる音
                }
            }
        });
    }
}

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
        console.log('[updateBookshelfDisplay] Applied: bookshelf-empty (dreamCount: 0)');
    } else if (dreamCount <= 3) {
        bookshelf.classList.add('bookshelf-small');
        console.log('[updateBookshelfDisplay] Applied: bookshelf-small (dreamCount:', dreamCount, ')');
    } else if (dreamCount <= 7) {
        bookshelf.classList.add('bookshelf-medium');
        console.log('[updateBookshelfDisplay] Applied: bookshelf-medium (dreamCount:', dreamCount, ')');
    } else {
        bookshelf.classList.add('bookshelf-large');
        console.log('[updateBookshelfDisplay] Applied: bookshelf-large (dreamCount:', dreamCount, ')');
    }
}

// TODO: Rails統合時は以下をAPI呼び出しに置き換え
// fetch('/api/v1/dreams')
//     .then(response => response.json())
//     .then(data => {
//         const dreamCount = data.dreams.length;
//         updateBookshelfDisplay(dreamCount);
//     })
//     .catch(error => {
//         console.error('Failed to fetch dreams:', error);
//         updateBookshelfDisplay(0); // エラー時は空の本棚を表示
//     });

// ダミーデータで動作確認（prototype段階）
// library.htmlが読み込まれた時にのみ実行
if (document.getElementById('bookshelf')) {
    const dummyDreamCount = 4; // 仮の夢の数（0, 1-3, 4-7, 8以上で本棚画像が変わる）
    updateBookshelfDisplay(dummyDreamCount);
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
        console.log('[updateScrollMiniDisplay] Applied: has-memo (LocalStorage scratchpad exists)');
    } else {
        deskScrollMini.classList.add('no-memo');
        console.log('[updateScrollMiniDisplay] Applied: no-memo (LocalStorage scratchpad empty)');
    }
}

// library.htmlが読み込まれた時にのみ実行
if (document.getElementById('desk-scroll-mini')) {
    updateScrollMiniDisplay();
}
