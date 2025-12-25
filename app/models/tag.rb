# == Schema Information
#
# Table name: tags
#
#  id         :bigint           not null, primary key
#  user_id    :bigint           not null
#  name       :string           not null
#  yomi       :string           not null
#  yomi_index :integer          not null
#  category   :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_tags_on_user_id                 (user_id)
#  index_tags_on_user_id_and_category    (user_id,category)
#  index_tags_on_user_id_and_name        (user_id,name) UNIQUE
#  index_tags_on_user_id_and_yomi        (user_id,yomi)
#  index_tags_on_user_id_and_yomi_index  (user_id,yomi_index)
#
class Tag < ApplicationRecord
  belongs_to :user
  has_many :dream_tags, dependent: :destroy
  has_many :dreams, through: :dream_tags

  # enum定義
  enum :category, { person: 0, place: 1 }
  enum :yomi_index, {
    'あ' => 0, 'か' => 1, 'さ' => 2, 'た' => 3, 'な' => 4,
    'は' => 5, 'ま' => 6, 'や' => 7, 'ら' => 8, 'わ' => 9,
    '英数字' => 10, '他' => 11
  }

  # バリデーション
  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :yomi, presence: true
  validates :category, presence: true
  validates :yomi_index, presence: true

  # before_validation: yomi_index 自動生成
  before_validation :set_yomi_index

  # スコープ
  scope :by_category, ->(cat) { where(category: cat) }
  scope :by_yomi_index, ->(idx) { where(yomi_index: idx) }
  scope :search_by_name_or_yomi, lambda { |query|
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
