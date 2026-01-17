---
name: test-development
description: Essential guide for all RSpec testing work including planning, design, and implementation. Apply this when discussing test strategies, designing test cases, planning test coverage, writing test specifications, implementing RSpec tests, or reviewing test quality. Always reference these principles before starting any testing-related work.
---

# テスト規約

RSpecテストに関する規約。

## テストの構成順序

テストは以下の順序で記述する：

1. **正常系**（有効なケース）
2. **異常系**（無効なケース）
3. **境界系**（制限値付近のケース）

## ファクトリ設計

### デフォルト値の原則

ファクトリのデフォルトは**最小限の有効な状態**を定義：

- **モデルデフォルトが存在する属性**: 省略（デフォルト値をテスト可能にするため）
- **必須だがデフォルトなしの属性**: 最もシンプルな有効値を設定

### バリエーション

バリエーションは**trait**で定義：

```ruby
FactoryBot.define do
  factory :user do
    username { "user_#{SecureRandom.hex(4)}" }
    email { "#{username}@example.com" }
    password { "password123" }

    trait :with_dreams do
      after(:create) do |user|
        create_list(:dream, 3, user: user)
      end
    end

    trait :admin do
      role { :admin }
    end
  end
end
```

## テストカバレッジ

- **目標**: 80%以上
- **重点**: ビジネスロジック、バリデーション、認証・認可

## フロントエンドテスト方針

- **バックエンド（API）**: TDD（RSpec）
- **フロントエンド**: 手動確認 + System Spec（E2E）

### System Spec（Capybara）で確認
- 画面遷移
- API連携
- 主要ユーザーフロー

### 手動確認
- 演出・アニメーション
- レスポンシブデザイン
- ブラウザ互換性
