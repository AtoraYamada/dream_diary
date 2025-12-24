# == Schema Information
#
# Table name: dream_tags
#
#  id         :bigint           not null, primary key
#  dream_id   :bigint           not null
#  tag_id     :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_dream_tags_on_dream_id             (dream_id)
#  index_dream_tags_on_dream_id_and_tag_id  (dream_id,tag_id) UNIQUE
#  index_dream_tags_on_tag_id               (tag_id)
#
require 'rails_helper'

RSpec.describe DreamTag, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
