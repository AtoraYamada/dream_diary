// index.js - Top page (forest door)

import { closeEyes, openEyes, checkAndOpenEyes, playSound, saveToLocalStorage, loadFromLocalStorage, navigateWithBlink } from '../common.js';

// DOMContentLoadedを待たずに即座に実行（dynamic import時点でDOMは準備完了）

const forestDoor = document.getElementById('forest-door');
const muteButton = document.getElementById('mute-button');
const scratchpadTrigger = document.getElementById('scratchpad-trigger');
const scratchpadOverlay = document.getElementById('scratchpad-overlay');
const scratchpadTextarea = document.getElementById('scratchpad-textarea');
const scratchpadCloseButton = document.querySelector('.scratchpad-close');

// Check for awakening mode (logout演出) - prioritize this over normal blink
const urlParams = new URLSearchParams(window.location.search);
if (urlParams.get('awakening') === 'true') {
    // Apply awakening class immediately (blur will be visible when eyes open)
    document.documentElement.classList.add('awakening');

    // CSS暗転からオーバーレイ暗転へ切り替え（スムーズな遷移のため）
    // will-open-eyesを削除する前に、オーバーレイで暗転を維持
    const initialOverlay = document.createElement('div');
    initialOverlay.classList.add('blink-overlay', 'closing');
    document.body.appendChild(initialOverlay);

    // CSS暗転を解除（オーバーレイで暗転は維持されている）
    document.documentElement.classList.remove('will-open-eyes');

    // Small delay to ensure blur CSS is applied before opening eyes
    setTimeout(() => {
        // First blink: open eyes to show blurred page
        // 既存のオーバーレイを使って開眼アニメーション
        requestAnimationFrame(() => {
            initialOverlay.classList.remove('closing');
            initialOverlay.classList.add('opening');

            setTimeout(() => {
                initialOverlay.remove();
            }, 500);
        });

        // After showing blurred page for 1s, do second blink
        setTimeout(() => {
            closeEyes(() => {
                // closeEyes callback: remove blur while eyes are closed (during blink)
                document.documentElement.classList.remove('awakening');

                // Clear URL parameter
                const newUrl = window.location.pathname;
                window.history.replaceState({}, document.title, newUrl);

                // Open eyes after brief pause to show clear page (without blur)
                setTimeout(() => {
                    openEyes();
                }, 100);
            });
        }, 1500); // Wait 1.5s in blurred state (500ms opening + 1000ms hold)
    }, 50); // Small delay for CSS to apply
} else {
    // Normal page transition - check for opening eyes animation
    checkAndOpenEyes();
}

let isMuted = false;

// Mute button functionality (UI要素: ミュートボタン)
muteButton.addEventListener('click', () => {
    isMuted = !isMuted;
    muteButton.textContent = isMuted ? '🔇' : '🔊';
    // Implement actual audio muting logic here
    playSound('sfx_ui_toggle.wav'); // Asset: UIトグル音
});

// Door click to transition to auth page
forestDoor.addEventListener('click', () => {
    // Read target path from data attribute
    const targetPath = forestDoor.dataset.targetPath;
    // Asset: 重厚な扉の開閉音
    navigateWithBlink(targetPath, 'sfx_door_open_heavy.wav');
});

// Scratchpad trigger
scratchpadTrigger.addEventListener('click', () => {
    scratchpadTrigger.style.opacity = '0'; // Fade out trigger first
    setTimeout(() => {
        scratchpadTrigger.style.display = 'none'; // Hide trigger
        scratchpadOverlay.classList.add('visible'); // Then fade in overlay
        // Load saved content
        const savedContent = loadFromLocalStorage('scratchpad_content');
        if (savedContent) {
            scratchpadTextarea.value = savedContent;
        }
        scratchpadTextarea.focus();
        playSound('sfx_paper_unfurl.wav'); // Asset: 紙が広がる音 (スクラッチパッド開く時)
    }, 300); // Wait for trigger fade out to complete
});

// Close scratchpad
scratchpadCloseButton.addEventListener('click', () => {
    scratchpadOverlay.classList.remove('visible'); // Fade out overlay
    setTimeout(() => {
        scratchpadTrigger.style.display = 'block'; // Show trigger
        setTimeout(() => scratchpadTrigger.style.opacity = '1', 10); // Fade in trigger
    }, 300); // Wait for overlay transition to complete
    playSound('sfx_ui_confirm.wav'); // Asset: 選択・決定音
});

// Save scratchpad content to LocalStorage on input
scratchpadTextarea.addEventListener('input', () => {
    // Enforce 2000 character limit
    if (scratchpadTextarea.value.length > 2000) {
        scratchpadTextarea.value = scratchpadTextarea.value.substring(0, 2000);
    }
    saveToLocalStorage('scratchpad_content', scratchpadTextarea.value);
    playSound('sfx_pencil_write.wav'); // Asset: 鉛筆の筆記音 (入力時)
});
