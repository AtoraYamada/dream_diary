require 'rails_helper'

RSpec.describe Dreams::AttachTagsService do
  let(:user) { create(:user) }
  let(:dream) { create(:dream, user: user) }

  describe '.call' do
    context 'tag_attributes が空の場合' do
      it '成功を返し、タグを追加しないこと' do
        result = described_class.call(dream, [])

        expect(result).to be_success
        expect(result.value).to eq(dream)
        expect(dream.tags).to be_empty
      end

      it 'nil の場合も成功を返すこと' do
        result = described_class.call(dream, nil)

        expect(result).to be_success
        expect(dream.tags).to be_empty
      end
    end

    context 'tag_attributes が存在する場合' do
      let(:tag_attributes) do
        [
          { name: '太郎', yomi: 'たろう', category: 'person' },
          { name: '古びた洋館', yomi: 'ふるびたようかん', category: 'place' }
        ]
      end

      it '新規タグを作成して関連付けること' do
        expect do
          result = described_class.call(dream, tag_attributes)
          expect(result).to be_success
        end.to change { user.tags.count }.by(2)
                                         .and change { dream.tags.count }.by(2)

        expect(dream.tags.pluck(:name)).to contain_exactly('太郎', '古びた洋館')
      end

      it 'yomi_index が自動設定されること' do
        result = described_class.call(dream, tag_attributes)

        expect(result).to be_success
        taro_tag = user.tags.find_by(name: '太郎')
        expect(taro_tag.yomi_index).to eq('た')
      end

      context '既存のタグが存在する場合' do
        let!(:existing_tag) { create(:tag, name: '太郎', yomi: 'たろう', category: 'person', user: user) }

        it '既存タグを再利用し、新規タグのみ作成すること' do
          expect do
            result = described_class.call(dream, tag_attributes)
            expect(result).to be_success
          end.to change { user.tags.count }.by(1) # '古びた洋館' のみ作成

          expect(dream.tags).to include(existing_tag)
          expect(dream.tags.pluck(:name)).to contain_exactly('太郎', '古びた洋館')
        end
      end

      context '重複タグを関連付けようとした場合' do
        before do
          described_class.call(dream, [tag_attributes.first])
        end

        it '重複を避けて関連付けること' do
          expect do
            result = described_class.call(dream, tag_attributes)
            expect(result).to be_success
          end.to change { dream.tags.count }.by(1) # '古びた洋館' のみ追加

          expect(dream.tags.pluck(:name)).to contain_exactly('太郎', '古びた洋館')
        end
      end
    end

    context 'バリデーションエラーが発生した場合' do
      let(:invalid_tag_attributes) do
        [{ name: '', yomi: '', category: 'person' }]
      end

      it '失敗を返し、エラーメッセージを含むこと' do
        result = described_class.call(dream, invalid_tag_attributes)

        expect(result).to be_failure
        expect(result.errors).not_to be_empty
      end
    end

    context '予期しないエラーが発生した場合' do
      it '失敗を返し、エラーメッセージを含むこと' do
        service = described_class.new(dream, [{ name: '太郎', yomi: 'たろう', category: 'person' }])
        allow(described_class).to receive(:new).and_return(service)
        allow(service).to receive(:attach_tags).and_raise(StandardError, 'テストエラー')

        result = described_class.call(dream, [{ name: '太郎', yomi: 'たろう', category: 'person' }])

        expect(result).to be_failure
        expect(result.errors).to include('栞の綴じ込みに失敗しました: テストエラー')
      end
    end
  end
end
