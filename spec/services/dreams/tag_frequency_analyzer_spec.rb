# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dreams::TagFrequencyAnalyzer do
  describe '.call' do
    let(:user) { create(:user) }

    context '直近10回分の夢から2回以上使われたタグが存在する場合' do
      let!(:tag1) { create(:tag, user: user, name: 'タグ1') }
      let!(:tag2) { create(:tag, user: user, name: 'タグ2') }
      let!(:tag3) { create(:tag, user: user, name: 'タグ3') }

      before do
        # 直近10回分の夢を作成（dreamed_at順）
        # tag1: 3回、tag2: 2回、tag3: 1回
        base_time = Time.current

        # 最新の夢（9日前〜0日前）
        9.downto(0) do |i|
          dream = create(:dream, user: user, dreamed_at: base_time - i.days)

          # tag1を3回含める（index 0, 3, 6）
          dream.tags << tag1 if [0, 3, 6].include?(i)

          # tag2を2回含める（index 1, 4）
          dream.tags << tag2 if [1, 4].include?(i)

          # tag3を1回含める（index 2）
          dream.tags << tag3 if i == 2
        end
      end

      it '2回以上使われたタグIDの配列を返すこと' do
        result = described_class.call(user)

        expect(result).to contain_exactly(tag1.id, tag2.id)
        expect(result).not_to include(tag3.id)
      end
    end

    context '夢が10件未満の場合' do
      let!(:tag1) { create(:tag, user: user, name: 'タグ1') }

      before do
        # 5件の夢を作成
        5.times do |i|
          dream = create(:dream, user: user, dreamed_at: Time.current - i.days)
          dream.tags << tag1 if i < 2 # tag1を2回使用
        end
      end

      it '存在する夢の中から2回以上使われたタグを返すこと' do
        result = described_class.call(user)

        expect(result).to contain_exactly(tag1.id)
      end
    end

    context '夢が0件の場合' do
      it '空配列を返すこと' do
        result = described_class.call(user)

        expect(result).to eq([])
      end
    end

    context '2回以上使われたタグがない場合' do
      before do
        # 10件の夢を作成し、各夢に異なるタグを1回ずつ使用
        10.times do |i|
          dream = create(:dream, user: user, dreamed_at: Time.current - i.days)
          tag = create(:tag, user: user, name: "ユニークタグ#{i}")
          dream.tags << tag
        end
      end

      it '空配列を返すこと' do
        result = described_class.call(user)

        expect(result).to eq([])
      end
    end

    context '11件目以降の夢のタグは含まれない' do
      let!(:tag1) { create(:tag, user: user, name: 'タグ1') }
      let!(:tag2) { create(:tag, user: user, name: 'タグ2') }

      before do
        base_time = Time.current

        # 直近10件（0〜9日前）: tag1を2回使用
        10.times do |i|
          dream = create(:dream, user: user, dreamed_at: base_time - i.days)
          dream.tags << tag1 if i < 2
        end

        # 11件目以降（10〜15日前）: tag2を3回使用
        6.times do |i|
          dream = create(:dream, user: user, dreamed_at: base_time - (10 + i).days)
          dream.tags << tag2 if i < 3
        end
      end

      it '直近10件のみを対象とし、11件目以降のタグは含まれないこと' do
        result = described_class.call(user)

        expect(result).to contain_exactly(tag1.id)
        expect(result).not_to include(tag2.id)
      end
    end

    context '複数ユーザーが存在する場合' do
      let(:user2) { create(:user) }
      let!(:tag1) { create(:tag, user: user, name: 'タグ1') }
      let!(:tag2) { create(:tag, user: user2, name: 'タグ2') }

      before do
        # user1の夢: tag1を2回使用
        2.times do |i|
          dream = create(:dream, user: user, dreamed_at: Time.current - i.days)
          dream.tags << tag1
        end

        # user2の夢: tag2を2回使用
        2.times do |i|
          dream = create(:dream, user: user2, dreamed_at: Time.current - i.days)
          dream.tags << tag2
        end
      end

      it '指定したユーザーのタグのみを返すこと' do
        result = described_class.call(user)

        expect(result).to contain_exactly(tag1.id)
        expect(result).not_to include(tag2.id)
      end
    end
  end
end
