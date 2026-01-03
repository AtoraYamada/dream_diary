# 02. データベース設計

## ER図

```
users (1) ─────< (N) dreams
                      │
                      │ (N)
                      └────< dream_tags >────┐
                                             │
                           tags (N) ──────────┘

users (1) ─────< (N) tags
```

**関係性**:
- User は複数の Dream を持つ（1:N）
- User は複数の Tag を持つ（1:N）
- Dream と Tag は多対多関係（中間テーブル: DreamTag）

---

## テーブル定義

### users テーブル（Devise生成）

**役割**: ユーザー認証・管理

| カラム名 | 型 | 制約 | 説明 |
|---------|---|------|------|
| id | bigint | PK | ユーザーID |
| email | string | NOT NULL, UNIQUE | メールアドレス |
| username | string | NOT NULL, UNIQUE | ユーザー名（追加） |
| encrypted_password | string | NOT NULL | 暗号化パスワード |
| reset_password_token | string | UNIQUE | パスワードリセット用 |
| reset_password_sent_at | datetime | - | リセット送信日時 |
| remember_created_at | datetime | - | ログイン記憶日時 |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

**インデックス**:
- `email` (unique)
- `username` (unique)
- `reset_password_token` (unique)

**マイグレーション追加内容**:
```ruby
# db/migrate/YYYYMMDDHHMMSS_add_username_to_users.rb
class AddUsernameToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :username, :string, null: false
    add_index :users, :username, unique: true
  end
end
```

---

### dreams テーブル

**役割**: 夢日記の本体データ

| カラム名 | 型 | 制約 | 説明 |
|---------|---|------|------|
| id | bigint | PK | 夢日記ID |
| user_id | bigint | FK, NOT NULL, indexed | ユーザーID |
| title | string(15) | NOT NULL | 夢のタイトル（15文字制限） |
| content | text | NOT NULL | 夢の本文（10,000文字制限） |
| emotion_color | integer | NOT NULL, default: 0 | 感情彩色（enum: 0=peace, 1=chaos, 2=fear, 3=elation） |
| lucid_dream_flag | boolean | default: false | 明晰夢フラグ（将来の拡張用、現在UIなし） |
| dreamed_at | datetime | NOT NULL, indexed | 夢を見た日 |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

**インデックス**:
- `user_id` (foreign key)
- `[user_id, dreamed_at]` (複合、検索用)
- `[user_id, emotion_color]` (複合、フィルタ用)
- `[user_id, title]` (検索用)

**マイグレーション**:
```ruby
# db/migrate/YYYYMMDDHHMMSS_create_dreams.rb
class CreateDreams < ActiveRecord::Migration[7.0]
  def change
    create_table :dreams do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false, limit: 15
      t.text :content, null: false
      t.integer :emotion_color, null: false
      t.boolean :lucid_dream_flag, default: false
      t.datetime :dreamed_at, null: false

      t.timestamps

      t.index [:user_id, :dreamed_at]
      t.index [:user_id, :emotion_color]
      t.index [:user_id, :title]
    end
  end
end
```

---

### tags テーブル

**役割**: タグマスター（登場人物・場所）

| カラム名 | 型 | 制約 | 説明 |
|---------|---|------|------|
| id | bigint | PK | タグID |
| user_id | bigint | FK, NOT NULL, indexed | ユーザーID |
| name | string | NOT NULL | タグ名（元の表記） |
| yomi | string | NOT NULL, indexed | 読み仮名（ひらがな） |
| yomi_index | string | NOT NULL, indexed | 五十音インデックス |
| category | integer | NOT NULL | カテゴリ（enum: 0=person, 1=place） |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

**yomi_index 値**:
- `'あ'`, `'か'`, `'さ'`, `'た'`, `'な'`, `'は'`, `'ま'`, `'や'`, `'ら'`, `'わ'`, `'英数字'`, `'他'`

**インデックス**:
- `user_id` (foreign key)
- `[user_id, name]` (unique)
- `[user_id, yomi]` (検索用)
- `[user_id, yomi_index]` (五十音絞り込み用)
- `[user_id, category]` (カテゴリ絞り込み用)

**マイグレーション**:
```ruby
# db/migrate/YYYYMMDDHHMMSS_create_tags.rb
class CreateTags < ActiveRecord::Migration[7.0]
  def change
    create_table :tags do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :yomi, null: false
      t.integer :yomi_index, null: false
      t.integer :category, null: false

      t.timestamps

      t.index [:user_id, :name], unique: true
      t.index [:user_id, :yomi]
      t.index [:user_id, :yomi_index]
      t.index [:user_id, :category]
    end
  end
end
```

---

### dream_tags テーブル（中間テーブル）

**役割**: Dream と Tag の多対多関係

| カラム名 | 型 | 制約 | 説明 |
|---------|---|------|------|
| id | bigint | PK | ID |
| dream_id | bigint | FK, NOT NULL | 夢日記ID |
| tag_id | bigint | FK, NOT NULL | タグID |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

**インデックス**:
- `[dream_id, tag_id]` (unique)
- `dream_id` (foreign key)
- `tag_id` (foreign key)

**マイグレーション**:
```ruby
# db/migrate/YYYYMMDDHHMMSS_create_dream_tags.rb
class CreateDreamTags < ActiveRecord::Migration[7.0]
  def change
    create_table :dream_tags do |t|
      t.references :dream, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps

      t.index [:dream_id, :tag_id], unique: true
    end
  end
end
```

---

## モデル実装

### User モデル（Devise）

```ruby
# app/models/user.rb
class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # アソシエーション
  has_many :dreams, dependent: :destroy
  has_many :tags, dependent: :destroy

  # バリデーション
  validates :username, presence: true, uniqueness: true
  # emailのバリデーションはDeviseの:validatableモジュールが自動的に提供
end
```

---

### Dream モデル

```ruby
# app/models/dream.rb
class Dream < ApplicationRecord
  belongs_to :user
  has_many :dream_tags, dependent: :destroy
  has_many :tags, through: :dream_tags

  # enum定義
  enum emotion_color: { peace: 0, chaos: 1, fear: 2, elation: 3 }

  # バリデーション
  validates :title, presence: true, length: { maximum: 15 }
  validates :content, presence: true, length: { maximum: 10000 }
  validates :emotion_color, presence: true
  validates :dreamed_at, presence: true

  # ※ カスタムエラーメッセージは config/locales/ja.yml で定義

  # スコープ
  scope :recent, -> { order(dreamed_at: :desc) }
  scope :by_emotion, ->(color) { where(emotion_color: color) }

  # キーワード検索（title + content）
  scope :search_by_keyword, ->(keyword) {
    return all if keyword.blank?
    sanitized = sanitize_sql_like(keyword)
    where('title LIKE ? OR content LIKE ?', "%#{sanitized}%", "%#{sanitized}%")
  }

  # タグ検索（AND条件）
  scope :tagged_with, ->(tag_ids) {
    return all if tag_ids.blank?
    joins(:tags)
      .where(tags: { id: tag_ids })
      .group('dreams.id')
      .having('COUNT(DISTINCT tags.id) = ?', tag_ids.size)
  }

  # XSS 対策: 保存前にコンテンツをサニタイズ
  before_save :sanitize_content

  private

  def sanitize_content
    # HTML タグと属性をすべて除去（プレーンテキストのみ保持）
    self.content = ActionController::Base.helpers.sanitize(
      self.content,
      tags: [],      # すべてのタグを除去
      attributes: [] # すべての属性を除去
    )
  end
end
```

**判断材料**:
- `lucid_dream_flag` は将来の拡張用（現在はUI・検索なし）
- `dreamed_at` のデフォルト値はフロントエンドで設定（現在日時）
- `emotion_color` は enum で管理（DB値: 0-3、コード値: peace/chaos/fear/elation）
- キーワード検索は `title` と `content` の両方を対象（LIKE検索）
- タグ検索は AND 条件（全てのタグを持つ夢のみ抽出）

---

### Tag モデル

```ruby
# app/models/tag.rb
class Tag < ApplicationRecord
  belongs_to :user
  has_many :dream_tags, dependent: :destroy
  has_many :dreams, through: :dream_tags

  # enum定義
  enum category: { person: 0, place: 1 }
  enum yomi_index: {
    'あ' => 0, 'か' => 1, 'さ' => 2, 'た' => 3, 'な' => 4,
    'は' => 5, 'ま' => 6, 'や' => 7, 'ら' => 8, 'わ' => 9,
    '英数字' => 10, '他' => 11
  }

  # バリデーション
  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :yomi, presence: true
  validates :yomi_index, presence: true
  validates :category, presence: true
  # ※ カスタムエラーメッセージは config/locales/ja.yml で定義

  # before_validation: yomi_index 自動生成
  before_validation :set_yomi_index

  # スコープ
  scope :by_category, ->(cat) { where(category: cat) }
  scope :by_yomi_index, ->(idx) { where(yomi_index: idx) }
  scope :search_by_name_or_yomi, ->(query) {
    return all if query.blank?
    sanitized = sanitize_sql_like(query)
    where('name LIKE ? OR yomi LIKE ?', "%#{sanitized}%", "%#{sanitized}%")
  }

  # ひらがな範囲マッピング（読み仮名インデックス自動判定用）
  YOMI_INDEX_RANGES = {
    'あ' => ('あ'..'お'),
    'か' => ('か'..'ご'),
    'さ' => ('さ'..'ぞ'),
    'た' => ('た'..'ど'),
    'な' => ('な'..'の'),
    'は' => ('は'..'ぽ'),
    'ま' => ('ま'..'も'),
    'や' => ('や'..'よ'),
    'ら' => ('ら'..'ろ'),
    'わ' => ('わ'..'ん')
  }.freeze

  private

  def set_yomi_index
    return if yomi.blank?

    first_char = yomi[0]

    self.yomi_index = if first_char.match?(/[a-zA-Z0-9]/)
                        '英数字'
                      else
                        YOMI_INDEX_RANGES.find { |_, range| range.include?(first_char) }&.first || '他'
                      end
  end
end
```

**判断材料**:
- `yomi` は kuromoji.js でフロントエンド生成（hidden input で送信）
- `yomi_index` は `before_validation` で自動生成（yomi の先頭文字から判定）
- 英数字判定: 正規表現 `/[a-zA-Z0-9]/`
- それ以外（記号など）: `'他'`

---

### DreamTag モデル（中間テーブル）

```ruby
# app/models/dream_tag.rb
class DreamTag < ApplicationRecord
  belongs_to :dream
  belongs_to :tag

  # バリデーション
  # belongs_toが暗黙的にdream/tagの存在をバリデーション（Rails 5+のデフォルト）
  validates :dream_id, uniqueness: { scope: :tag_id }

  # ※ カスタムエラーメッセージは config/locales/ja.yml で定義
end
```

---

## テスト仕様

**テスト構成**: 正常系/異常系/境界系で分類し、`full_messages_for` を使用して完全なエラーメッセージをテスト

### Model Spec（例：Dream）

```ruby
# spec/models/dream_spec.rb
require 'rails_helper'

RSpec.describe Dream, type: :model do
  subject { build(:dream) }

  # アソシエーション
  it { should belong_to(:user) }
  it { should have_many(:dream_tags).dependent(:destroy) }
  it { should have_many(:tags).through(:dream_tags) }

  # バリデーション
  it { should validate_presence_of(:title) }
  it { should validate_length_of(:title).is_at_most(15) }
  it { should validate_presence_of(:content) }
  it { should validate_length_of(:content).is_at_most(10000) }
  it { should validate_presence_of(:emotion_color) }
  it { should validate_presence_of(:dreamed_at) }

  # enum
  it { is_expected.to define_enum_for(:emotion_color).with_values(peace: 0, chaos: 1, fear: 2, elation: 3) }

  # スコープ
  describe '.search_by_keyword' do
    let!(:mansion_dream) { create(:dream, title: '古びた洋館', content: '地下室の奥で') }
    let!(:forest_dream) { create(:dream, title: '森の記憶', content: '木陰で休む') }
    let!(:library_dream) { create(:dream, title: '静かな図書館', content: '古びた本を探す') }

    it 'タイトルで検索できる' do
      expect(Dream.search_by_keyword('洋館')).to include(mansion_dream)
      expect(Dream.search_by_keyword('洋館')).not_to include(forest_dream, library_dream)
    end

    it '本文で検索できる' do
      expect(Dream.search_by_keyword('地下室')).to include(mansion_dream)
      expect(Dream.search_by_keyword('地下室')).not_to include(forest_dream, library_dream)
    end

    it 'title と content 両方でキーワード検索できる（OR条件）' do
      result = Dream.search_by_keyword('古びた')
      expect(result).to include(mansion_dream, library_dream) # mansion_dreamはtitle、library_dreamはcontentでヒット
      expect(result).not_to include(forest_dream)
    end
  end

  describe '.tagged_with' do
    let(:user) { create(:user) }
    let(:person_tag) { create(:tag, name: '太郎', user: user) }
    let(:place_tag) { create(:tag, name: '洋館', user: user) }
    let!(:tagged_dream_with_both) { create(:dream, user: user, tags: [person_tag, place_tag]) }
    let!(:tagged_dream_with_person) { create(:dream, user: user, tags: [person_tag]) }

    it '指定したタグを全て持つ夢のみ抽出される（AND条件）' do
      result = Dream.tagged_with([person_tag.id, place_tag.id])
      expect(result).to include(tagged_dream_with_both)
      expect(result).not_to include(tagged_dream_with_person)
    end
  end
end
```

### FactoryBot定義

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "user#{n}" }
    password { 'password123' }
    password_confirmation { 'password123' }
  end
end

# spec/factories/dreams.rb
FactoryBot.define do
  factory :dream do
    association :user
    title { '夢のタイトル' }
    content { '夢の内容が記述されます。' }
    emotion_color { :peace } # Factory default (model defaultではない)
    dreamed_at { Time.current }
    # lucid_dream_flag omitted - model default (false) をテストするため

    trait :lucid do
      lucid_dream_flag { true }
    end

    trait :chaos do
      emotion_color { :chaos }
    end

    trait :fear do
      emotion_color { :fear }
    end

    trait :elation do
      emotion_color { :elation }
    end

    trait :with_tags do
      after(:create) do |dream|
        create_list(:tag, 2, user: dream.user, dreams: [dream])
      end
    end
  end
end

# spec/factories/tags.rb
FactoryBot.define do
  factory :tag do
    association :user
    sequence(:name) { |n| "タグ#{n}" }
    yomi { 'たぐ' }
    category { :person }
    # yomi_index omitted - before_validation callback で自動設定されるため

    trait :place do
      category { :place }
    end

    trait :with_custom_yomi do
      yomi { 'かすたむ' }
      # yomi_index は callback で 'か' に自動設定される
    end
  end
end

# spec/factories/dream_tags.rb
FactoryBot.define do
  factory :dream_tag do
    association :dream
    association :tag
  end
end
```

---

## テスト環境設定

### shoulda-matchers設定（spec/rails_helper.rb）

```ruby
require 'shoulda-matchers'

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
```

### カスタムエラーメッセージ（config/locales/ja.yml）

```yaml
ja:
  activerecord:
    models:
      dream: "夢"
      tag: "栞"
      dream_tag: "綴じ込み"
      user: "利用者"

    attributes:
      dream:
        title: "夢の銘"
        content: "夢の残滓"
        emotion_color: "夢見る心の色相"
        dreamed_at: "夢との邂逅の刻"
        user: "筆録者"

      tag:
        name: "栞の銘"
        yomi: "栞の読み"
        yomi_index: "栞の目録"
        category: "栞の種別"
        user: "筆録者"

      dream_tag:
        dream: "夢"
        tag: "栞"

      user:
        username: "利用者名"
        email: "連絡の灯火"
        password: "記憶の鍵"
        password_confirmation: "2本目の記憶の鍵"

    errors:
      models:
        dream:
          attributes:
            title:
              blank: "が記された形跡がありません"
              too_long: "が長すぎます（最大15文字）"
            content:
              blank: "が記された形跡がありません"
              too_long: "が大きすぎて本に収まりません（最大10,000文字）"
            emotion_color:
              blank: "が選ばれていません"
              inclusion: "の作法が異なっているようです"
            dreamed_at:
              blank: "が記録されていません"
            user:
              blank: "が誰か不明です"
              required: "が誰か不明です"

        tag:
          attributes:
            name:
              blank: "が記された形跡がありません"
              taken: "は既に記されています"
            yomi:
              blank: "が記された形跡がありません"
            yomi_index:
              blank: "が不明です"
              inclusion: "の作法が異なっているようです"
            category:
              blank: "が不明です"
              inclusion: "の作法が異なっているようです"
            user:
              blank: "が誰か不明です"
              required: "が誰か不明です"

        dream_tag:
          attributes:
            dream:
              blank: "が行方不明です"
              required: "が行方不明です"
            tag:
              blank: "が行方不明です"
              required: "が行方不明です"
            dream_id:
              blank: "が行方不明です"
              taken: "には既にこの栞が綴じ込められています"
            tag_id:
              blank: "が行方不明です"

        user:
          attributes:
            username:
              blank: "が記された形跡がありません"
              taken: "は既に蔵書目録に刻まれています"
            email:
              blank: "が灯されておりません"
              taken: "は別の場所で灯っているようです"
              invalid: "に必要な「印」が刻まれていません"
            password:
              blank: "を携えていないようです"
              too_short: "の強度が足りません（最小6文字）"
            password_confirmation:
              confirmation: "と1本目の記憶の鍵が一致しません"
    errors:
      messages:
        record_invalid: "バリデーションに失敗しました: %{errors}"
```

### RuboCop設定（.rubocop.yml）

RSpec関連のルールを実用的に緩和します：

```yaml
# let! を setup データとして使用することを許可
RSpec/LetSetup:
  Enabled: false

# インデックス付きlet変数名を許可
RSpec/IndexedLet:
  Enabled: false

# memoized helpers の上限を引き上げ
RSpec/MultipleMemoizedHelpers:
  Max: 10

# subject に名前を付けなくても OK
RSpec/NamedSubject:
  Enabled: false

# 複数の expect を許可
RSpec/MultipleExpectations:
  Max: 10

# テスト例の長さを緩和
RSpec/ExampleLength:
  Max: 20
```

---

## マイグレーションコマンドまとめ

```bash
# モデル生成
docker compose exec web rails g model Dream user:references title:string content:text emotion_color:integer lucid_dream_flag:boolean dreamed_at:datetime
docker compose exec web rails g model Tag user:references name:string yomi:string yomi_index:string category:integer
docker compose exec web rails g model DreamTag dream:references tag:references

# マイグレーション実行
docker compose exec web rails db:migrate

# ロールバック
docker compose exec web rails db:rollback

# マイグレーション状態確認
docker compose exec web rails db:migrate:status
```

---

## データ制約まとめ

| モデル | フィールド | 制約 | 理由 |
|-------|-----------|------|------|
| Dream | title | 15文字 | 背表紙の縦書き表示に対応 |
| Dream | content | 10,000文字 | データ肥大化防止、通信遅延防止 |
| Dream | lucid_dream_flag | デフォルト false | 将来の拡張用（現在UIなし） |
| Tag | name | user_id スコープで unique | ユーザー内でタグ名の重複を防止 |
| Tag | yomi_index | 自動生成 | yomi の先頭文字から判定 |

---

## 初期データ（Seed Data）

### ユーザー作成時の自動生成データ

**新規ユーザー登録時、以下のチュートリアル本を自動生成**:

| フィールド | 値 |
|-----------|-----|
| title | 「書斎の使い方」|
| content | [世界観に合わせた物語] 例：「この書斎の先代の主（ある夢遊病者の手記）の記録。君もここで夢を記すのだろう...」等の導入テキスト + 操作方法説明 |
| emotion_color | 0（peace） |
| lucid_dream_flag | false |
| dreamed_at | ユーザー作成時刻 |

### 削除制限なし
- チュートリアル本も通常の夢日記と同様に削除（砂時計で「忘却」）可能

### 実装方法

**app/models/user.rb**:
```ruby
class User < ApplicationRecord
  has_many :dreams, dependent: :destroy
  has_many :tags, dependent: :destroy

  after_create :create_tutorial_dream

  private

  def create_tutorial_dream
    self.dreams.create!(
      title: '書斎の使い方',
      content: 'この書斎の先代の主（ある夢遊病者の手記）の記録。君もここで夢を記すのだろう...',
      emotion_color: 0, # peace
      lucid_dream_flag: false,
      dreamed_at: Time.current
    )
  end
end
```

---

## 実装ガイドライン

### マイグレーションコメント

マイグレーションファイルには、テーブルとカラムにコメントを追加してください。

**テーブルコメント**:
```ruby
create_table :users, comment: 'ユーザー認証・管理' do |t|
  # ...
end
```

**カラムコメント**:
```ruby
t.string :email, null: false, default: "", comment: 'メールアドレス'
t.string :username, null: false, comment: 'ユーザー名'
t.datetime :created_at, null: false, comment: '作成日時'
```

**timestampsコメント**:
```ruby
t.timestamps null: false, comment: '作成日時・更新日時'
```

**効果**:
- データベース構造の理解が容易になる
- PostgreSQL の `\d+ table_name` でコメントが表示される
- チーム開発でのドキュメント性向上

---

### Schema Annotation（annotate gem 使用）

**annotate gem** を使用して、モデルファイルに Schema Information を自動追加します。

#### 使用方法

**全モデルに Schema Information を自動追加**:
```bash
docker compose exec web annotate --models -i
```

**マイグレーション実行後に自動更新**（推奨）:
```bash
# マイグレーション実行
docker compose exec web rails db:migrate

# annotate 実行
docker compose exec web annotate --models -i
```

#### 生成される Schema Information の例

```ruby
# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  username               :string           not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_username              (username) UNIQUE
#
class User < ApplicationRecord
  # ...
end
```

#### 効果

- モデルファイルを開くだけでテーブル構造が分かる
- カラム名、型、制約、インデックスが一目瞭然
- マイグレーション後の自動更新で常に最新の状態を保つ

---

このファイルは、データベース設計の実装ガイドです。
Day 2（モデル生成・実装）で参照してください。
