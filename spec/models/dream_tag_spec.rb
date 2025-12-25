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
  subject { build(:dream_tag) }

  # ========================================
  # アソシエーション
  # ========================================
  describe 'アソシエーション' do
    it { is_expected.to belong_to(:dream) }
    it { is_expected.to belong_to(:tag) }
  end

  # ========================================
  # バリデーション
  # ========================================
  describe 'バリデーション' do
    # shoulda-matchers による基本テスト
    # belongs_toが暗黙的にバリデーション（Rails 5+）するため、明示的なpresenceテストは不要
    # it { is_expected.to validate_presence_of(:dream_id) }
    # it { is_expected.to validate_presence_of(:tag_id) }

    # --- 正常系 ---
    describe '正常系' do
      context '全ての必須項目が正しく入力されている場合' do
        let(:dream_tag) { build(:dream_tag) }

        it 'バリデーションが通る' do
          expect(dream_tag).to be_valid
        end
      end

      context '異なるdreamに同じtagを関連付ける場合' do
        let(:user) { create(:user) }
        let(:tag) { create(:tag, user: user) }
        let(:dream1) { create(:dream, user: user) }
        let(:dream2) { create(:dream, user: user) }
        let!(:dream_tag1) { create(:dream_tag, dream: dream1, tag: tag) }
        let(:dream_tag2) { build(:dream_tag, dream: dream2, tag: tag) }

        it 'バリデーションが通る' do
          expect(dream_tag2).to be_valid
        end
      end

      context '同じdreamに異なるtagを関連付ける場合' do
        let(:user) { create(:user) }
        let(:dream) { create(:dream, user: user) }
        let(:tag1) { create(:tag, user: user, name: 'タグ1') }
        let(:tag2) { create(:tag, user: user, name: 'タグ2') }
        let!(:dream_tag1) { create(:dream_tag, dream: dream, tag: tag1) }
        let(:dream_tag2) { build(:dream_tag, dream: dream, tag: tag2) }

        it 'バリデーションが通る' do
          expect(dream_tag2).to be_valid
        end
      end
    end

    # --- 異常系 ---
    describe '異常系' do
      context 'dreamが関連付けられていない場合' do
        let(:dream_tag) { build(:dream_tag, dream: nil) }

        it 'バリデーションエラーが発生する' do
          expect(dream_tag).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          dream_tag.valid?
          expect(dream_tag.errors.full_messages_for(:dream)).to eq(['夢 が行方不明です'])
        end
      end

      context 'tagが関連付けられていない場合' do
        let(:dream_tag) { build(:dream_tag, tag: nil) }

        it 'バリデーションエラーが発生する' do
          expect(dream_tag).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          dream_tag.valid?
          expect(dream_tag.errors.full_messages_for(:tag)).to eq(['栞 が行方不明です'])
        end
      end

      context '同じdreamとtagの組み合わせが既に存在する場合' do
        let(:user) { create(:user) }
        let(:dream) { create(:dream, user: user) }
        let(:tag) { create(:tag, user: user) }
        let!(:dream_tag1) { create(:dream_tag, dream: dream, tag: tag) }
        let(:dream_tag2) { build(:dream_tag, dream: dream, tag: tag) }

        it 'バリデーションエラーが発生する' do
          expect(dream_tag2).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          dream_tag2.valid?
          expect(dream_tag2.errors.full_messages_for(:dream_id)).to eq(['夢 には既にこの栞が綴じ込められています'])
        end
      end
    end
  end
end
