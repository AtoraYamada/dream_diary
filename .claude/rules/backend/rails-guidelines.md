---
paths:
  - "app/**/*.rb"
  - "spec/**/*.rb"
  - "db/migrate/**/*.rb"
---

# Rails実装ガイドライン

Ruby on Railsコード全般に適用される規約。

## 実装プロセス (TDD)

**Red → Green → Refactor** のサイクルを厳守する：

1. **Red**: 失敗するテストを書く
2. **Green**: テストを通す最小限のコードを書く
3. **Refactor**: コードを整理・改善する

## アーキテクチャ

- **Fat Model, Skinny Controller**: ビジネスロジックはモデルに配置
- **Service Object**: 複雑なビジネスロジックはService Objectに切り出す
- **関心の分離**: 各クラス・メソッドは単一の責任を持つ

## セキュリティとパフォーマンス

**必ず防止すること**:
- N+1クエリ（`includes`, `joins`, `preload`を適切に使用）
- SQLインジェクション（パラメータ化クエリ、Strong Parameters使用）
- XSS（Rails標準のエスケープ機能を活用）

## マイグレーション

必ずrollbackテストを実施：

```bash
docker compose exec web rails db:migrate && \
docker compose exec web rails db:rollback && \
docker compose exec web rails db:migrate
```

## 完了の定義 (Definition of Done)

以下すべてを満たすこと：

- [ ] テストが通っている（カバレッジ80%以上を目標）
- [ ] RuboCopのエラーがない
- [ ] Brakemanのセキュリティ警告がない
- [ ] Railsアプリが正常に動作する
