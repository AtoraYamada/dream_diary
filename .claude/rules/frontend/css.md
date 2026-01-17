---
paths:
  - "app/assets/stylesheets/**/*.css"
---

# CSS規約

カスタムCSSに関する規約。

## ファイル構成

```
app/assets/stylesheets/
├── application.css      # エントリーポイント
├── base.css             # 基本スタイル
├── layout.css           # レイアウト共通
├── blink.css            # 瞬き演出
├── components/
│   ├── buttons.css      # ボタン
│   ├── cursors.css      # カーソル
│   └── modal/           # モーダル各種
└── pages/
    ├── auth.css         # 認証画面
    ├── index.css        # トップ画面
    ├── library.css      # 書斎画面
    └── list.css         # 一覧画面
```

## 設計原則

- **コンポーネント単位**: 再利用可能なスタイルをcomponents/に配置
- **ページ単位**: 画面固有のスタイルをpages/に配置
- **BEM風命名**: `.auth-card`, `.auth-card-login` など明確な命名
- **CSS Variables**: 色・サイズの共通化（必要に応じて）

## 命名規則

- **ケバブケース**: `kebab-case`（例: `.auth-card-wrapper`）
- **意味のある名前**: 見た目ではなく役割を表現
- **モディファイア**: `--`で区切る（例: `.button--primary`）

## アニメーション

- CSS transitionsを活用
- JavaScriptとの連携時は、クラスの追加・削除で制御
- 演出仕様は `docs/specs/animations.md` を参照
