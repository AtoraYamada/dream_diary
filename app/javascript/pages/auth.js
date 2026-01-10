// auth.js - Authentication page (login/signup)

import { checkAndOpenEyes, navigateWithBlink, playSound } from '../common.js';

// DOMContentLoadedを待たずに即座に実行（dynamic import時点でDOMは準備完了）

// Check for opening eyes animation (from page transition)
checkAndOpenEyes();

const backButton = document.getElementById('back-to-index-button');
const authCardWrapper = document.getElementById('auth-card-wrapper');
const loginCard = document.getElementById('login-card');
const signupCard = document.getElementById('signup-card');
const loginForm = document.getElementById('login-form');
const signupForm = document.getElementById('signup-form');
const loginError = document.getElementById('login-error');
const signupError = document.getElementById('signup-error');

// Read paths from data attributes
const rootPath = backButton.dataset.rootPath;
const libraryPath = document.body.dataset.libraryPath;

// Back to index button
backButton.addEventListener('click', () => {
    playSound('sfx_ui_confirm.wav'); // Asset: 選択・決定音
    navigateWithBlink(rootPath);
});

// Click on signup card (initially behind) to bring it to front
signupCard.addEventListener('click', (e) => {
    // Only switch cards if clicking on the card itself, not form elements
    if (!authCardWrapper.classList.contains('signup-active') &&
        e.target === signupCard) {
        e.preventDefault(); // Prevent form submission when just switching cards
        playSound('sfx_auth_card_slide.wav'); // Asset: カードの摩擦音
        authCardWrapper.classList.add('signup-active');
        // Clear any error messages when switching views
        loginError.textContent = '';
        signupError.textContent = '';
        loginError.classList.remove('crumble');
        signupError.classList.remove('crumble');
    }
});

// Click on login card (behind when signup is active) to bring it to front
loginCard.addEventListener('click', (e) => {
    // Only switch cards if clicking on the card itself, not form elements
    if (authCardWrapper.classList.contains('signup-active') &&
        e.target === loginCard) {
        e.preventDefault(); // Prevent form submission when just switching cards
        playSound('sfx_auth_card_slide.wav'); // Asset: カードの摩擦音
        authCardWrapper.classList.remove('signup-active');
        // Clear any error messages when switching views
        loginError.textContent = '';
        signupError.textContent = '';
        loginError.classList.remove('crumble');
        signupError.classList.remove('crumble');
    }
});

// Simulate login success/failure
loginForm.addEventListener('submit', (event) => {
    event.preventDefault();
    const username = loginForm.querySelector('input[type="text"]').value;
    const password = loginForm.querySelector('input[type="password"]').value;

    loginError.textContent = ''; // Clear previous error
    loginError.classList.remove('crumble');

    if (username === 'user' && password === 'pass') {
        // playSound('sfx_boundary_pass.wav'); // Asset: 境界を越える音
        navigateWithBlink(libraryPath); // Transition to main hub
    } else {
        loginError.textContent = '入館を拒まれました。';
        loginError.classList.add('crumble');
        // playSound('sfx_sand_crumble.wav'); // Asset: 砂の崩落音（さらさら）
    }
});

// Simulate signup success/failure
signupForm.addEventListener('submit', (event) => {
    event.preventDefault();
    const newUsername = signupForm.querySelector('input[type="text"]').value;
    const newPassword = signupForm.querySelectorAll('input[type="password"]')[0].value;
    const confirmPassword = signupForm.querySelectorAll('input[type="password"]')[1].value;

    signupError.textContent = ''; // Clear previous error
    signupError.classList.remove('crumble');

    if (newPassword !== confirmPassword) {
        signupError.textContent = 'パスワードが一致しません。';
        signupError.classList.add('crumble');
        // playSound('sfx_sand_crumble.wav'); // Asset: 砂の崩落音（さらさら）
    } else if (newUsername === 'user') { // Simulate username taken
        signupError.textContent = 'そのユーザー名は既に存在します。';
        signupError.classList.add('crumble');
        // playSound('sfx_sand_crumble.wav'); // Asset: 砂の崩落音（さらさら）
    }
    else {
        // Auto-login after successful signup
        // playSound('sfx_boundary_pass.wav'); // Asset: 境界を越える音
        navigateWithBlink(libraryPath); // Transition to main hub
    }
});
