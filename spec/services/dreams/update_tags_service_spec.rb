require 'rails_helper'

RSpec.describe Dreams::UpdateTagsService do
  let(:user) { create(:user) }
  let(:dream) { create(:dream, user: user) }

  describe '.call' do
    context '既存のタグがある場合' do
      let!(:existing_tag1) { create(:tag, user: user, name: '既存タグ1') }
      let!(:existing_tag2) { create(:tag, user: user, name: '既存タグ2') }

      before do
        dream.tags << [existing_tag1, existing_tag2]
      end

      it '既存のタグをクリアして新しいタグを関連付けること' do
        new_tag_attributes = [
          { name: '新タグ1', yomi: 'しんたぐ1', category: 'person' },
          { name: '新タグ2', yomi: 'しんたぐ2', category: 'place' }
        ]

        result = described_class.call(dream, new_tag_attributes)

        expect(result).to be_success
        expect(dream.tags.count).to eq(2)
        expect(dream.tags.pluck(:name)).to contain_exactly('新タグ1', '新タグ2')
        expect(dream.tags.pluck(:name)).not_to include('既存タグ1', '既存タグ2')
      end

      it '空配列を渡すと全てのタグをクリアすること' do
        result = described_class.call(dream, [])

        expect(result).to be_success
        expect(dream.tags).to be_empty
      end
    end

    context '既存のタグがない場合' do
      it '新しいタグを関連付けること' do
        new_tag_attributes = [
          { name: 'タグA', yomi: 'たぐA', category: 'person' }
        ]

        result = described_class.call(dream, new_tag_attributes)

        expect(result).to be_success
        expect(dream.tags.count).to eq(1)
        expect(dream.tags.first.name).to eq('タグA')
      end
    end
  end
end
