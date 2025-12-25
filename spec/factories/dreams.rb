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
FactoryBot.define do
  factory :dream do
    association :user
    title { '夢のタイトル' }
    content { '夢の内容が記述されます。' }
    emotion_color { :peace }
    dreamed_at { Time.current }
    # lucid_dream_flag はデフォルト値（false）をテストするため指定しない

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
