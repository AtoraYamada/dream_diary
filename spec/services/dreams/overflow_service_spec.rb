require 'rails_helper'

RSpec.describe Dreams::OverflowService do
  let(:user) { create(:user) }

  describe '.call' do
    context '十分な夢が存在する場合' do
      let!(:dreams) do
        [
          create(:dream, user: user, content: '遠くで鐘が鳴っている。古びた洋館が見える。'),
          create(:dream, user: user, content: '月が二つ見える。森の奥から声が聞こえる。'),
          create(:dream, user: user, content: '時計が逆回りしている。窓の外に影がある。')
        ]
      end

      it '成功を返し、5〜8個のフラグメントを返すこと' do
        result = described_class.call(dreams)

        expect(result).to be_success
        expect(result.value).to be_an(Array)
        expect(result.value.size).to be_between(5, 8)
      end

      it 'フラグメントが句点で分割されていること' do
        result = described_class.call(dreams)

        expect(result).to be_success
        # 元の文章から抽出されたフラグメントを含むこと
        all_fragments = result.value.join
        expect(all_fragments).to match(/遠くで鐘が鳴っている|古びた洋館が見える|月が二つ見える/)
      end

      it 'ランダムに選択されること' do
        # 複数回実行して、異なる結果が返されることを確認
        results = 10.times.map { described_class.call(dreams).value }
        unique_results = results.uniq(&:sort)

        # 少なくとも2種類以上の異なる結果が返されること（ランダム性の検証）
        expect(unique_results.size).to be >= 2
      end
    end

    context 'フラグメントが5個未満の場合' do
      let!(:dreams) do
        [create(:dream, user: user, content: '短い夢。')]
      end

      it 'フォールバックフラグメントを含めて返すこと' do
        result = described_class.call(dreams)

        expect(result).to be_success
        expect(result.value.size).to be_between(5, 8)

        # フォールバックフラグメントが含まれていること
        fallback_included = result.value.any? do |fragment|
          Dreams::OverflowService::FALLBACK_FRAGMENTS.include?(fragment)
        end
        expect(fallback_included).to be true
      end
    end

    context '夢が存在しない場合' do
      let(:dreams) { [] }

      it 'フォールバックフラグメントのみを返すこと' do
        result = described_class.call(dreams)

        expect(result).to be_success
        expect(result.value.size).to be_between(5, 8)

        # すべてフォールバックフラグメントであること
        expect(result.value).to all(be_in(Dreams::OverflowService::FALLBACK_FRAGMENTS))
      end
    end

    context '予期しないエラーが発生した場合' do
      it '失敗を返し、エラーメッセージを含むこと' do
        service = described_class.new([])
        allow(described_class).to receive(:new).and_return(service)
        allow(service).to receive(:extract_fragments).and_raise(StandardError, 'テストエラー')

        result = described_class.call([])

        expect(result).to be_failure
        expect(result.errors).to include('夢の氾濫に失敗しました: テストエラー')
      end
    end
  end
end
