// scroll_modal.js - Scroll modal (create/edit) common logic

import { closeEyes, openEyes, playSound } from '../common.js';

/**
 * 感情と色の対応定数
 */
export const emotionColors = {
    peace: '#a0a9a6',
    chaos: '#b07a70',
    fear: '#838387',
    elation: '#ca9e63'
};

/**
 * インクボトルの感情選択イベントを初期化
 */
export function initializeInkBottleSelection() {
    const inkBottles = document.querySelectorAll('.ink-bottle');
    const scrollMiddle = document.querySelector('.scroll-middle');

    inkBottles.forEach(bottle => {
        bottle.addEventListener('click', () => {
            const emotion = bottle.dataset.emotion;

            // 全てのボトルから選択状態を解除
            inkBottles.forEach(b => b.classList.remove('selected'));

            // クリックしたボトルを選択状態に
            bottle.classList.add('selected');

            // scroll-middleの背景色を変更
            if (scrollMiddle && emotionColors[emotion]) {
                scrollMiddle.style.backgroundColor = emotionColors[emotion];
            }

            playSound('sfx_ui_confirm.wav'); // Asset: 選択・決定音
        });
    });
}

/**
 * 巻物モーダルを開く共通関数
 * @param {Object} options - オプション
 * @param {Function} options.onBeforeOpen - 瞬き前に実行するコールバック（縮小巻物非表示など）
 * @param {Function} options.onAfterOpen - 開眼後に実行するコールバック
 */
export function openScrollModal(options = {}) {
    const createEditModalOverlay = document.getElementById('create-edit-modal-overlay');
    const scrollMiddle = document.querySelector('.scroll-middle');

    // 瞬き演出を実行
    closeEyes(() => {
        // 瞬き前のコールバック実行（library: 縮小版巻物とテキストを非表示）
        if (options.onBeforeOpen) {
            options.onBeforeOpen();
        }

        // 瞬き中にモーダルオーバーレイを表示（巻物は見えない状態：scroll-middle height 0）
        createEditModalOverlay.classList.add('active');

        // 開眼を実行（50msの小さなバッファを追加して、モーダル表示を確実に）
        setTimeout(() => {
            openEyes();

            // 目が開いた後、点滅アニメーション完了後に巻物の展開アニメーションを開始
            setTimeout(() => {
                scrollMiddle.classList.add('unfurl');
                // playSound('sfx_scroll_unfurl.wav'); // Asset: 巻物を広げる音

                // 開眼後のコールバック実行
                if (options.onAfterOpen) {
                    options.onAfterOpen();
                }
            }, 500); // openEyes()の点滅アニメーション完了を待つ
        }, 50);
    });
}

/**
 * 巻物モーダルを閉じる共通関数
 * @param {Object} options - オプション
 * @param {Function} options.beforeBlink - 瞬き前に実行するコールバック（栞の発光演出など）
 * @param {number} options.beforeBlinkDelay - beforeBlinkコールバック完了待機時間（ms、デフォルト0）
 * @param {Function} options.duringBlink - 瞬き中に実行するコールバック（フォームクリア、縮小巻物再表示など）
 * @param {Function} options.afterBlink - 開眼後に実行するコールバック（本の背表紙を光らせるなど）
 */
export function closeScrollModal(options = {}) {
    const createEditModalOverlay = document.getElementById('create-edit-modal-overlay');
    const scrollMiddle = document.querySelector('.scroll-middle');
    const inkBottles = document.querySelectorAll('.ink-bottle');

    // 瞬き前のコールバック実行（栞の発光演出など）
    const executeBeforeBlink = () => {
        if (options.beforeBlink) {
            options.beforeBlink();
        }
    };

    // 瞬き前処理を実行
    executeBeforeBlink();

    // beforeBlinkDelay待機後に巻物収縮アニメーション開始
    const beforeBlinkDelay = options.beforeBlinkDelay || 0;
    setTimeout(() => {
        // 巻物収縮アニメーション開始
        scrollMiddle.classList.remove('unfurl');
        scrollMiddle.classList.add('roll-up');
        // playSound('sfx_scroll_roll_up.wav'); // Asset: 巻物の収束音

        // 巻物収縮完了後に瞬きを実行（巻物から本への遷移を隠蔽、または机に戻す）
        setTimeout(() => {
            closeEyes(() => {
                // 瞬き中にモーダルを確実に消すため、transitionを一時的に無効化
                createEditModalOverlay.style.transition = 'none';

                // 瞬き中にモーダルを閉じる
                createEditModalOverlay.classList.remove('active');
                scrollMiddle.classList.remove('unfurl', 'roll-up');

                // 残像を完全に消すため、heightを明示的に0にリセット
                scrollMiddle.style.height = '0';

                // scroll-middleの色とインクボトルの選択状態をリセット（瞬き中）
                if (scrollMiddle) {
                    scrollMiddle.style.backgroundColor = ''; // CSSデフォルトに戻す
                }
                inkBottles.forEach(b => b.classList.remove('selected'));

                // 瞬き中のコールバック実行（フォームクリア、縮小巻物再表示など）
                if (options.duringBlink) {
                    options.duringBlink();
                }

                // 瞬き明け
                setTimeout(() => {
                    openEyes();

                    // 次回表示のため、transitionを元に戻す
                    setTimeout(() => {
                        createEditModalOverlay.style.transition = '';

                        // 開眼後のコールバック実行（本の背表紙を光らせるなど）
                        if (options.afterBlink) {
                            options.afterBlink();
                        }
                    }, 100);
                }, 50);
            });
        }, 600); // 巻物アニメーション時間に合わせる（0.6s = 600ms）
    }, beforeBlinkDelay);
}
