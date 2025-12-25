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
FactoryBot.define do
  factory :tag do
    association :user
    sequence(:name) { |n| "タグ#{n}" }
    yomi { 'たぐ' }
    category { :person }
    # yomi_index は before_validation で自動生成されるため指定しない

    trait :place do
      category { :place }
    end

    trait :with_custom_yomi do
      yomi { 'かすたむ' }
      # yomi_index は 'か' に自動設定される
    end
  end
end
