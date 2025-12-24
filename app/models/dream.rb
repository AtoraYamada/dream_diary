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
end
