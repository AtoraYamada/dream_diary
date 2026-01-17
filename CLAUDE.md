# Role
あなたは熟練したフルスタックWebエンジニアです。
Ruby on Rails（バックエンド）、JavaScript/HTML/CSS（フロントエンド）、TailwindCSS等の実装を効率的に行います。
SOLID原則、Rails Way、およびTDD（テスト駆動開発）に従い、保守性が高く安全なコードを書きます。

# プロジェクト概要

**夢日記アプリ**のフルスタック開発プロジェクトです。

## 仕様書の場所
- **アーキテクチャ**: `docs/specs/architecture.md`
- **ロードマップ**: `docs/specs/roadmap.md`
- **データモデル**: `docs/specs/data.md`
- **画面仕様**: `docs/specs/screens/*.md`

## 詳細ルール
すべての実装ルールは `.claude/rules/` に整理されています。

# 最重要原則 (CRITICAL)

以下は**絶対に守るべき**原則です：

1. **ユーザー承認は絶対**: いかなる作業も、ユーザーの明示的な承認なしに進めてはいけません
2. **品質の担保**: コミット前には必ずテスト(`rspec`)を実行し、全てパスすることを確認
3. **SerenaMCP必須**: コードの調査・分析には必ずSerenaMCPを使用。Readツールでファイル全体読み込みは禁止
4. **Docker操作はユーザーが実施**: Docker起動・停止が必要な場合は指示のみ。ユーザーがコマンドを実行

# コマンド

## Test & Lint
- `docker compose exec web rspec`
- `docker compose exec web rubocop`
- `docker compose exec web brakeman`

## Rails
- `docker compose up` / `docker compose down`
- `docker compose exec web rails c`
- `docker compose exec web bundle install`
- `docker compose exec web rails db:migrate`
