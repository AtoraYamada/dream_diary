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
      t.integer :emotion_color, null: false, default: 0
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
      t.string :yomi_index, null: false
      t.integer :category, null: false

      t.timestamps

      t.index [:user_id, name], unique: true
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
  validates :username, presence: true, uniqueness: true, length: { minimum: 3, maximum: 20 }
  validates :email, presence: true, uniqueness: true
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

  # スコープ
  scope :recent, -> { order(dreamed_at: :desc) }
  scope :by_emotion, ->(color) { where(emotion_color: color) }

  # キーワード検索（title + content）
  scope :search_by_keyword, ->(keyword) {
    return all if keyword.blank?
    where("title LIKE ? OR content LIKE ?", "%#{keyword}%", "%#{keyword}%")
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

  # before_validation: yomi_index 自動生成
  before_validation :set_yomi_index

  # スコープ
  scope :by_category, ->(cat) { where(category: cat) }
  scope :by_yomi_index, ->(idx) { where(yomi_index: idx) }
  scope :search_by_name_or_yomi, ->(query) {
    return all if query.blank?
    where("name LIKE ? OR yomi LIKE ?", "%#{query}%", "%#{query}%")
  }

  private

  def set_yomi_index
    return if yomi.blank?

    first_char = yomi[0]

    # 判定ロジック（優先順位順）
    self.yomi_index = case first_char
    when 'あ'..'お' then 'あ'
    when 'か'..'ご' then 'か'
    when 'さ'..'ぞ' then 'さ'
    when 'た'..'ど' then 'た'
    when 'な'..'の' then 'な'
    when 'は'..'ぽ' then 'は'
    when 'ま'..'も' then 'ま'
    when 'や'..'よ' then 'や'
    when 'ら'..'ろ' then 'ら'
    when 'わ'..'ん' then 'わ'
    when /[a-zA-Z0-9]/ then '英数字'
    else '他'
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
  validates :dream_id, presence: true
  validates :tag_id, presence: true
  validates :dream_id, uniqueness: { scope: :tag_id }
end
```

---

## テスト仕様

### Model Spec（例：Dream）

```ruby
# spec/models/dream_spec.rb
require 'rails_helper'

RSpec.describe Dream, type: :model do
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
  it { should define_enum_for(:emotion_color).with_values(peace: 0, chaos: 1, fear: 2, elation: 3) }

  # スコープ
  describe '.search_by_keyword' do
    let!(:dream1) { create(:dream, title: '古びた洋館', content: '地下室の奥で') }
    let!(:dream2) { create(:dream, title: '森の記憶', content: '木陰で休む') }

    it 'タイトルで検索できる' do
      expect(Dream.search_by_keyword('洋館')).to include(dream1)
      expect(Dream.search_by_keyword('洋館')).not_to include(dream2)
    end

    it '本文で検索できる' do
      expect(Dream.search_by_keyword('地下室')).to include(dream1)
    end
  end

  describe '.tagged_with' do
    let(:user) { create(:user) }
    let(:tag1) { create(:tag, name: '太郎', user: user) }
    let(:tag2) { create(:tag, name: '洋館', user: user) }
    let!(:dream1) { create(:dream, user: user, tags: [tag1, tag2]) }
    let!(:dream2) { create(:dream, user: user, tags: [tag1]) }

    it '指定したタグを全て持つ夢のみ抽出される' do
      result = Dream.tagged_with([tag1.id, tag2.id])
      expect(result).to include(dream1)
      expect(result).not_to include(dream2)
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
    emotion_color { :peace }
    dreamed_at { Time.current }
    lucid_dream_flag { false }
  end
end

# spec/factories/tags.rb
FactoryBot.define do
  factory :tag do
    association :user
    sequence(:name) { |n| "タグ#{n}" }
    yomi { 'たぐ' }
    yomi_index { 'た' }
    category { :person }
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

このファイルは、データベース設計の実装ガイドです。
Day 2（モデル生成・実装）で参照してください。
