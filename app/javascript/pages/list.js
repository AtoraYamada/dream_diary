// list.js - List page (bookshelf view with book spines, detail modal, edit modal)

import { emotionColors, closeScrollModal, initializeInkBottleSelection } from '../modals/scroll_modal.js';
import { closeEyes, openEyes, playSound, initiateBlinkTransition, toHiragana, navigateWithBlink, checkAndOpenEyes } from '../common.js';

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
        if (!selectedTagsContainer) return;

        // 既存のバッジのみを削除（ラベルは残す）
        const existingBadges = selectedTagsContainer.querySelectorAll('.tag-badge');
        existingBadges.forEach(badge => badge.remove());

        // ラベルが存在しない場合のみ作成
        let labelSpan = selectedTagsContainer.querySelector('.label');
        if (!labelSpan) {
            labelSpan = document.createElement('span');
            labelSpan.className = 'label';
            labelSpan.textContent = '選択中の索引：';
            selectedTagsContainer.prepend(labelSpan);
        }

        // 選択されたタグのバッジを作成
        selectedTagNames.forEach(tagName => {
            const badge = document.createElement('div');
            badge.className = 'tag-badge';

            // テキストノードとして追加
            const tagText = document.createTextNode(tagName);
            badge.appendChild(tagText);

            const removeBtn = document.createElement('span');
            removeBtn.className = 'remove-btn';
            removeBtn.textContent = '×';
            removeBtn.onclick = (event) => {
                event.stopPropagation();
                selectedTagNames.delete(tagName);

                // CSS.escapeを使用して特殊文字をエスケープ
                const cardToDeselect = cardList.querySelector(`.tag-card[data-tag-name="${CSS.escape(tagName)}"]`);
                if(cardToDeselect) {
                    cardToDeselect.classList.remove('selected');
                }

                updateSelectedTagsDisplay();
                playSound('sfx_ui_confirm.wav');
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

                indexCardModal.classList.remove('visible');
                if (indexBoxTrigger) indexBoxTrigger.style.display = 'block'; // Show trigger when modal closes
            });
        });
    }

    // Match button (抽出) functionality
    if (matchButton) {
        matchButton.addEventListener('click', () => {
            playSound('sfx_ui_confirm.wav'); // Asset: 選択・決定音 (検索実行)

            // モーダル外クリック時と同じ処理を使用
            const indexCardModal = document.getElementById('index-card-modal');
            const indexBoxTrigger = document.getElementById('index-box-trigger');
            initiateBlinkTransition(() => {
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

// グローバル変数: 現在開いている本の感情とIDを保持
let currentBookEmotion = 'chaos';
let currentBookId = null;

// グローバル関数: 詳細モーダルを開く
function openDetailModalInList(bookId, emotion = 'chaos') {
    const detailModalOverlay = document.getElementById('detail-modal-overlay');
    const bookFrame = document.querySelector('.book-frame');
    const leftPage = document.getElementById('left-page');
    const rightPage = document.getElementById('right-page');

    // 現在の感情とIDを保存
    currentBookEmotion = emotion;
    currentBookId = bookId;

    // 瞬き演出を実行（閉眼）
    closeEyes(() => {
        // 感情に応じてbook-frameの背景画像を変更
        const emotionFrames = {
            peace: 'url("assets/img_book_open_frame_peace.png")',
            chaos: 'url("assets/img_book_open_frame_chaos.png")',
            fear: 'url("assets/img_book_open_frame_fear.png")',
            elation: 'url("assets/img_book_open_frame_elation.png")'
        };
        if (bookFrame && emotionFrames[emotion]) {
            bookFrame.style.backgroundImage = emotionFrames[emotion];
        }

        // closeEyesのコールバック：300ms後に実行される（閉眼完了）
        // モーダルを表示
        detailModalOverlay.classList.add('active');

        // 見開き本に内容を表示
        leftPage.innerHTML = `
            <p>左ページの内容。これは夢日記の詳細表示画面です。ここに夢の内容が記述されます。昔々、あるところに…。</p>
            <p>夜の帳が降り、静寂が世界を包み込む頃、私の意識は深い森の奥へと誘われた。そこには古びた石の門があり、蔦に覆われたその扉は、まるで遥か昔からそこに存在し続けているかのように見えた。微かな月明かりが、湿った土の道を照らし、私の足元に細く白い筋を描き出していた。</p>
            <p>門の向こうには、霧に霞む庭園が広がっていた。手入れのされていない薔薇の木々が、鋭い棘を夜空に突き刺し、その先にはさらに古い洋館の影が横たわっていた。窓は全て黒く、まるで巨大な眼窩のようだった。私は恐怖と好奇心に駆られ、一歩、また一歩と、その未知の領域へと足を踏み入れた。</p>
        `;

        rightPage.innerHTML = `
            <p>右ページの内容。続きや詳細情報がここに表示されます。この夢は平穏の色に染まっていた。</p>
            <p>洋館の中は、外観とは裏腹に、不思議なほど温かい空気に満ちていた。薄暗いホールには、埃を被った肖像画が何枚も飾られており、彼らの視線が私を追っているかのように感じられた。遠くから微かに聞こえるオルゴールの音色は、どこか懐かしく、しかし同時に不穏な響きを帯びていた。</p>
            <p>私は最奥の部屋へと導かれた。そこには、大きな窓から差し込む満月光を浴びて、一冊の古めかしい本が開かれていた。羊皮紙のページには、理解できない古代文字が記されており、私はその意味を探ろうと、必死に目を凝らした。その瞬間、窓の外から眩い光が差し込み、私の意識は急激に覚醒へと向かっていった。</p>
        `;

        // 開眼を実行（50msの小さなバッファを追加して、モーダル表示を確実に）
        setTimeout(() => {
            openEyes();
        }, 50);
    });
}

// グローバル関数: 詳細モーダルを閉じる
function closeDetailModalInList() {
    const detailModalOverlay = document.getElementById('detail-modal-overlay');

    // モーダルを非表示（瞬き演出なし）
    detailModalOverlay.classList.remove('active');
}

// Export global functions
window.openDetailModalInList = openDetailModalInList;
window.closeDetailModalInList = closeDetailModalInList;

// Check for opening eyes animation (from page transition)
checkAndOpenEyes();

const backButton = document.getElementById('back-to-library-button');
const bookSpinesContainer = document.getElementById('book-spines-container');
const paginationLeft = document.getElementById('pagination-left');
const paginationRight = document.getElementById('pagination-right');
const indexBoxTrigger = document.getElementById('index-box-trigger');
const detailModalOverlay = document.getElementById('detail-modal-overlay');

// Index Card Modal elements
const indexCardModal = document.getElementById('index-card-modal');

// Read paths from data attributes
const libraryPath = document.body.dataset.libraryPath;

// 詳細モーダル外クリックで閉じる
detailModalOverlay.addEventListener('click', (e) => {
    if (e.target === detailModalOverlay) {
        closeDetailModalInList();
    }
});

// 編集ボタンクリック → 巻物モーダルへ遷移
const detailEditButton = document.getElementById('detail-edit-button');
const createEditModalOverlay = document.getElementById('create-edit-modal-overlay');
const scrollMiddle = document.querySelector('.scroll-middle');

detailEditButton.addEventListener('click', () => {
    playSound('sfx_ui_confirm.wav'); // Asset: 選択・決定音

    closeEyes(() => {
        // 詳細モーダルを確実に消すため、transitionを一時的に無効化
        detailModalOverlay.style.transition = 'none';

        // a. 詳細モーダルを閉じる
        detailModalOverlay.classList.remove('active');

        // b. 巻物モーダルを折り畳み状態で表示（scroll-middleは既にheight: 0）
        createEditModalOverlay.classList.add('active');

        // 現在の本の感情に応じてインクボトルを選択し、背景色を設定
        const inkBottles = document.querySelectorAll('.ink-bottle');
        inkBottles.forEach(bottle => {
            if (bottle.dataset.emotion === currentBookEmotion) {
                bottle.classList.add('selected');
            } else {
                bottle.classList.remove('selected');
            }
        });

        // scroll-middleの背景色を設定
        if (scrollMiddle && emotionColors[currentBookEmotion]) {
            scrollMiddle.style.backgroundColor = emotionColors[currentBookEmotion];
        }

        // 開眼
        setTimeout(() => {
            openEyes();

            // 詳細モーダルのtransitionを元に戻す
            setTimeout(() => {
                detailModalOverlay.style.transition = '';
            }, 100);

            // 開眼後、巻物の伸長アニメーション（600ms）
            setTimeout(() => {
                scrollMiddle.classList.add('unfurl');
            }, 500);
        }, 50);
    });
});

// 巻物モーダル外クリックで閉じる
createEditModalOverlay.addEventListener('click', (e) => {
    if (e.target === createEditModalOverlay) {
        closeScrollModal({});
    }
});

// Save Bookmark click (巻物モーダルを保存して閉じる)
const saveBookmark = document.getElementById('list-save-bookmark');

saveBookmark.addEventListener('click', () => {
    // 栞の発光演出
    saveBookmark.classList.add('glow');
    playSound('sfx_ui_confirm.wav'); // Asset: 選択・決定音

    closeScrollModal({
        beforeBlink: () => {
            // glowクラスは外側で管理（300ms待機）
        },
        beforeBlinkDelay: 300, // bookmark-glowアニメーションの時間
        afterBlink: () => {
            // glowクラスを削除
            saveBookmark.classList.remove('glow');

            // 開眼後、保存した本の背表紙を光らせる
            if (currentBookId) {
                const bookSpine = document.querySelector(`.book-spine[data-id="${currentBookId}"]`);
                if (bookSpine) {
                    bookSpine.classList.add('glow');

                    // アニメーション終了後にglowクラスを削除
                    setTimeout(() => {
                        bookSpine.classList.remove('glow');
                    }, 3000); // アニメーション時間と同じ（3s）
                }
            }
        }
    });
});

// Ink bottle click (感情選択 - scroll-middleの背景色変更)
initializeInkBottleSelection();

backButton.addEventListener('click', () => {
    playSound('sfx_ui_confirm.wav'); // Asset: 選択・決定音
    navigateWithBlink(libraryPath);
});

// Book spine click to detail modal (モーダル方式)
bookSpinesContainer.addEventListener('click', (event) => {
    const bookSpine = event.target.closest('.book-spine');
    if (bookSpine) {
        const bookId = bookSpine.dataset.id;

        // 感情クラスを取得（peace, chaos, fear, elation）
        let emotion = 'chaos'; // デフォルト
        if (bookSpine.classList.contains('peace')) emotion = 'peace';
        else if (bookSpine.classList.contains('chaos')) emotion = 'chaos';
        else if (bookSpine.classList.contains('fear')) emotion = 'fear';
        else if (bookSpine.classList.contains('elation')) emotion = 'elation';

        playSound('sfx_ui_confirm.wav'); // Asset: 選択・決定音

        // list.html内のモーダル関数を呼び出す（感情を渡す）
        openDetailModalInList(bookId, emotion);
    }
});

// Pagination (placeholder)
paginationLeft.addEventListener('click', () => {
    playSound('sfx_screen_slide.wav'); // Asset: 画面スライド音
    initiateBlinkTransition(() => {
        // In a real app, load previous page data here
    });
});

paginationRight.addEventListener('click', () => {
    playSound('sfx_screen_slide.wav'); // Asset: 画面スライド音
    initiateBlinkTransition(() => {
        // In a real app, load next page data here
    });
});

// Index Box click to open modal
indexBoxTrigger.addEventListener('click', () => {
    playSound('sfx_index_box_open_close.wav'); // Asset: 索引箱の開閉音
    initiateBlinkTransition(() => {
        indexBoxTrigger.style.display = 'none'; // Hide trigger when modal opens
        indexCardModal.classList.add('visible');
    });
});


// Close modal by clicking outside the drawer
indexCardModal.addEventListener('click', (event) => {
    if (event.target === indexCardModal) {
        playSound('sfx_index_box_open_close.wav'); // Asset: 索引箱の開閉音
        initiateBlinkTransition(() => {
            indexCardModal.classList.remove('visible');
            indexBoxTrigger.style.display = 'block'; // Show trigger when modal closes
        });
    }
});

// Initialize index card modal once on page load
initIndexCardModal();
