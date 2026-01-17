---
name: frontend-development
description: Essential guide for all frontend work including planning, design, and implementation. Apply this when discussing UI features, designing page interactions, planning animations, writing frontend specifications, implementing JavaScript/CSS, or reviewing frontend code. Covers vanilla JavaScript, custom CSS, ERB templates, and dream diary app styling.
---

# フロントエンド開発規約

JavaScriptとCSSに関する規約。

## 技術スタック

- **Vanilla JavaScript**: フレームワークを使用しないシンプルな実装
- **カスタムCSS**: コンポーネント別・ページ別に整理されたCSS
- **ERB**: Railsテンプレートエンジン

## JavaScript規約

### 基本原則

- **プログレッシブエンハンスメント**: JavaScriptなしでも基本機能が動作する
- **明示的な動作**: データ属性やIDで要素を特定
- **シンプルな実装**: 複雑なロジックはバックエンドに配置
- **ページ別JavaScript**: `app/javascript/pages/` に画面ごとのファイルを配置

### ファイル構成

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

### コーディング規約

- **イベントリスナー**: DOMContentLoaded後に登録
- **要素の取得**: `getElementById()`, `querySelector()` を使用
- **モーダル・アニメーション**: 統一されたopen/close処理、CSS transitionとの連携

### JSセキュリティ規約

- **出力制御**: `textContent` を原則とし、`innerHTML` はサニタイズ（DOMPurify等）必須とする。
- **Rails連携**: 非GETリクエストには `X-CSRF-Token` ヘッダーを付与し、`credentials: 'same-origin'` を設定すること。
- **実行禁止**: `eval()`, `new Function()`, `setTimeout(string)` 等の動的コード実行を一切禁止する。
- **データ保護**: 認証情報は `HttpOnly` クッキーで管理し、JS側（LocalStorage等）に機密情報を保持しない。
- **防御層**: フロントのバリデーションはUI補助とし、セキュリティの担保はサーバー側バリデーションで行う。
- **堅牢性**: オブジェクト操作時のプロトタイプ汚染対策（特殊キーの除外）を意識したコードを書くこと。

## CSS規約

### ファイル構成

```
app/assets/stylesheets/
├── application.css      # エントリーポイント
├── base.css             # 基本スタイル
├── layout.css           # レイアウト共通
├── blink.css            # 瞬き演出
├── components/          # 再利用可能なコンポーネント
└── pages/               # 画面固有のスタイル
```

### 設計原則

- **コンポーネント単位**: 再利用可能なスタイルをcomponents/に配置
- **ページ単位**: 画面固有のスタイルをpages/に配置
- **BEM風命名**: `.auth-card`, `.auth-card-login` など明確な命名
- **CSS Variables**: 色・サイズの共通化（必要に応じて）

### 命名規則

- **ケバブケース**: `kebab-case`（例: `.auth-card-wrapper`）
- **意味のある名前**: 見た目ではなく役割を表現
- **モディファイア**: `--`で区切る（例: `.button--primary`）

### アニメーション

- CSS transitionsを活用
- JavaScriptとの連携時は、クラスの追加・削除で制御
- 演出仕様は `docs/specs/animations.md` を参照

## テスト

- **System Spec**: 主要ユーザーフロー
- **手動確認**: アニメーション、レスポンシブ、ブラウザ互換性
