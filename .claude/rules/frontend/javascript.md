---
paths:
  - "app/javascript/**/*.js"
  - "app/views/**/*.html.erb"
---

# フロントエンド JavaScript規約

JavaScriptとERBテンプレートに関する規約。

## 技術スタック

- **Vanilla JavaScript**: フレームワークを使用しないシンプルな実装
- **カスタムCSS**: コンポーネント別・ページ別に整理されたCSS
- **ERB**: Railsテンプレートエンジン

## 基本原則

- **プログレッシブエンハンスメント**: JavaScriptなしでも基本機能が動作する
- **明示的な動作**: データ属性やIDで要素を特定
- **シンプルな実装**: 複雑なロジックはバックエンドに配置
- **ページ別JavaScript**: `app/javascript/pages/` に画面ごとのファイルを配置

## ファイル構成

```
app/javascript/
├── application.js      # エントリーポイント
├── common.js           # 共通処理
├── pages/
│   ├── auth.js         # 認証画面
│   ├── index.js        # トップ画面
│   ├── library.js      # 書斎画面
│   └── list.js         # 一覧画面
└── modals/
    └── scroll_modal.js # モーダル関連
```

## コーディング規約

### イベントリスナー
- DOMContentLoaded後に登録
- 適切なスコープでイベントを管理

### 要素の取得
- `getElementById()`, `querySelector()` を使用
- 明確なID・クラス名を付与

### モーダル・アニメーション
- 統一されたopen/close処理
- CSS transitionとの連携

## テスト

- **System Spec**: 主要ユーザーフロー
- **手動確認**: アニメーション、レスポンシブ、ブラウザ互換性
