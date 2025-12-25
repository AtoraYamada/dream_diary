# == Schema Information
#
# Table name: dreams
#
#  id               :bigint           not null, primary key
#  user_id          :bigint           not null
#  title            :string(15)       not null
#  content          :text             not null
#  emotion_color    :integer          not null
#  lucid_dream_flag :boolean          default(FALSE)
#  dreamed_at       :datetime         not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_dreams_on_user_id                    (user_id)
#  index_dreams_on_user_id_and_dreamed_at     (user_id,dreamed_at)
#  index_dreams_on_user_id_and_emotion_color  (user_id,emotion_color)
#  index_dreams_on_user_id_and_title          (user_id,title)
#
class Dream < ApplicationRecord
  belongs_to :user
  has_many :dream_tags, dependent: :destroy
  has_many :tags, through: :dream_tags

  # enum定義
  enum :emotion_color, { peace: 0, chaos: 1, fear: 2, elation: 3 }

  # バリデーション
  validates :title, presence: true, length: { maximum: 15 }
  validates :content, presence: true, length: { maximum: 10_000 }
  validates :dreamed_at, presence: true
  validates :emotion_color, presence: true

  # スコープ
  scope :recent, -> { order(dreamed_at: :desc) }
  scope :by_emotion, ->(color) { where(emotion_color: color) }

  # キーワード検索（title + content）
  scope :search_by_keyword, lambda { |keyword|
    return all if keyword.blank?

    sanitized = sanitize_sql_like(keyword)
    where('title LIKE ? OR content LIKE ?', "%#{sanitized}%", "%#{sanitized}%")
  }

  # タグ検索（AND条件）
  scope :tagged_with, lambda { |tag_ids|
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
      content,
      tags: [],      # すべてのタグを除去
      attributes: [] # すべての属性を除去
    )
  end
end
