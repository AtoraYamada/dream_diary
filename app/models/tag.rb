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
end
