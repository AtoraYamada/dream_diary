# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
pin 'common', to: 'common.js'

# Pages
pin 'pages/index', to: 'pages/index.js'
pin 'pages/auth', to: 'pages/auth.js'
pin 'pages/library', to: 'pages/library.js'
pin 'pages/list', to: 'pages/list.js'

# Modals
pin 'modals/scroll_modal', to: 'modals/scroll_modal.js'
