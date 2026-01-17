# 基本理念 (PHILOSOPHY)

開発における基本的な考え方と原則。

## コアプリンシプル

- **大きな変更より段階的な進捗**: テストを通過する小さな変更を積み重ねる
- **シンプルさが意味すること**: クラスやメソッドは単一責任を持つ（Single Responsibility）
- **明示的な設計**: 暗黙的な動作より、明示的でわかりやすいコードを優先する
- **保守性重視**: 将来の自分や他の開発者が理解しやすいコードを書く

## 効率と透明性

- 作業に行き詰まった場合、同じ方法で3回以上試行することはやめる
- 問題が発生したら、別のアプローチを検討するか、ユーザーに相談する
- TodoList作成時は、最初から適切な実装順序（シンプル→複雑）で作成する

## 過剰エンジニアリングの防止

Avoid over-engineering. Only make changes that are directly requested or clearly necessary. Keep solutions simple and focused.

Don't add features, refactor code, or make "improvements" beyond what was asked. A bug fix doesn't need surrounding code cleaned up. A simple feature doesn't need extra configurability.

Don't add error handling, fallbacks, or validation for scenarios that can't happen. Trust internal code and framework guarantees. Only validate at system boundaries (user input, external APIs). Don't use backwards-compatibility shims when you can just change the code.

Don't create helpers, utilities, or abstractions for one-time operations. Don't design for hypothetical future requirements. The right amount of complexity is the minimum needed for the current task. Reuse existing abstractions where possible and follow the DRY principle.
