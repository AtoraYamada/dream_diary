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
require 'rails_helper'

RSpec.describe Dream, type: :model do
  subject { build(:dream) }

  # ========================================
  # アソシエーション
  # ========================================
  describe 'アソシエーション' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:dream_tags).dependent(:destroy) }
    it { is_expected.to have_many(:tags).through(:dream_tags) }
  end

  # ========================================
  # バリデーション
  # ========================================
  describe 'バリデーション' do
    # shoulda-matchers による基本テスト
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(15) }
    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_length_of(:content).is_at_most(10_000) }
    it { is_expected.to validate_presence_of(:emotion_color) }
    it { is_expected.to validate_presence_of(:dreamed_at) }

    # --- 正常系 ---
    describe '正常系' do
      context '全ての必須項目が正しく入力されている場合' do
        let(:dream) { build(:dream) }

        it 'バリデーションが通る' do
          expect(dream).to be_valid
        end
      end

      context 'titleが15文字の場合' do
        let(:dream) { build(:dream, title: 'a' * 15) }

        it 'バリデーションが通る' do
          expect(dream).to be_valid
        end
      end

      context 'contentが10000文字の場合' do
        let(:dream) { build(:dream, content: 'a' * 10_000) }

        it 'バリデーションが通る' do
          expect(dream).to be_valid
        end
      end
    end

    # --- 異常系 ---
    describe '異常系' do
      context 'titleがnilの場合' do
        let(:dream) { build(:dream, title: nil) }

        it 'バリデーションエラーが発生する' do
          expect(dream).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          dream.valid?
          expect(dream.errors.full_messages_for(:title)).to eq(['夢の銘 が記された形跡がありません'])
        end
      end

      context 'titleが空文字の場合' do
        let(:dream) { build(:dream, title: '') }

        it 'バリデーションエラーが発生する' do
          expect(dream).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          dream.valid?
          expect(dream.errors.full_messages_for(:title)).to eq(['夢の銘 が記された形跡がありません'])
        end
      end

      context 'contentがnilの場合' do
        let(:dream) { build(:dream, content: nil) }

        it 'バリデーションエラーが発生する' do
          expect(dream).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          dream.valid?
          expect(dream.errors.full_messages_for(:content)).to eq(['夢の残滓 が記された形跡がありません'])
        end
      end

      context 'contentが空文字の場合' do
        let(:dream) { build(:dream, content: '') }

        it 'バリデーションエラーが発生する' do
          expect(dream).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          dream.valid?
          expect(dream.errors.full_messages_for(:content)).to eq(['夢の残滓 が記された形跡がありません'])
        end
      end

      context 'emotion_colorがnilの場合' do
        let(:dream) { build(:dream, emotion_color: nil) }

        it 'バリデーションエラーが発生する' do
          expect(dream).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          dream.valid?
          expect(dream.errors.full_messages_for(:emotion_color)).to eq(['夢見る心の色相 が選ばれていません'])
        end
      end

      context 'dreamed_atがnilの場合' do
        let(:dream) { build(:dream, dreamed_at: nil) }

        it 'バリデーションエラーが発生する' do
          expect(dream).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          dream.valid?
          expect(dream.errors.full_messages_for(:dreamed_at)).to eq(['夢との邂逅の刻 が記録されていません'])
        end
      end

      context 'userが関連付けられていない場合' do
        let(:dream) { build(:dream, user: nil) }

        it 'バリデーションエラーが発生する' do
          expect(dream).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          dream.valid?
          expect(dream.errors.full_messages_for(:user)).to eq(['筆録者 が誰か不明です'])
        end
      end
    end

    # --- 境界系 ---
    describe '境界系' do
      context 'titleが16文字の場合' do
        let(:dream) { build(:dream, title: 'a' * 16) }

        it 'バリデーションエラーが発生する' do
          expect(dream).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          dream.valid?
          expect(dream.errors.full_messages_for(:title)).to eq(['夢の銘 が長すぎます（最大15文字）'])
        end
      end

      context 'contentが10001文字の場合' do
        let(:dream) { build(:dream, content: 'a' * 10_001) }

        it 'バリデーションエラーが発生する' do
          expect(dream).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          dream.valid?
          expect(dream.errors.full_messages_for(:content)).to eq(['夢の残滓 が大きすぎて本に収まりません（最大10,000文字）'])
        end
      end
    end
  end

  # ========================================
  # enum
  # ========================================
  describe 'enum' do
    it { is_expected.to define_enum_for(:emotion_color).with_values(peace: 0, chaos: 1, fear: 2, elation: 3) }

    # --- 正常系 ---
    describe '正常系' do
      context '有効なemotion_color値を設定した場合' do
        let(:dream) { build(:dream, :chaos) }

        it '正しく設定される' do
          expect(dream.emotion_color).to eq('chaos')
        end
      end
    end

    # --- 異常系 ---
    describe '異常系' do
      context 'バリデーション時に範囲外の値が設定されている場合' do
        let(:dream) { build(:dream) }

        before do
          # enum setterをバイパスして不正な値を直接設定
          dream.save(validate: false)
          dream.update_column(:emotion_color, 999)
        end

        it 'バリデーションエラーが発生する' do
          expect(dream).to be_invalid
        end

        it 'inclusionエラーメッセージが表示される' do
          dream.valid?
          expect(dream.errors.full_messages_for(:emotion_color)).to eq(['夢見る心の色相 の作法が異なっているようです'])
        end
      end
    end
  end

  # ========================================
  # スコープ
  # ========================================
  describe 'スコープ' do
    describe '.recent' do
      let(:user) { create(:user) }
      let!(:older_dream) { create(:dream, user: user, dreamed_at: 2.days.ago) }
      let!(:recent_dream) { create(:dream, user: user, dreamed_at: 1.day.ago) }
      let!(:oldest_dream) { create(:dream, user: user, dreamed_at: 3.days.ago) }

      it '夢を見た日時の降順で返す' do
        expect(described_class.recent).to eq([recent_dream, older_dream, oldest_dream])
      end
    end

    describe '.by_emotion' do
      let(:user) { create(:user) }
      let!(:peace_dream) { create(:dream, user: user, emotion_color: :peace) }
      let!(:chaos_dream) { create(:dream, :chaos, user: user) }

      it '指定した感情の色でフィルタする' do
        expect(described_class.by_emotion(:peace)).to include(peace_dream)
        expect(described_class.by_emotion(:peace)).not_to include(chaos_dream)
      end
    end

    describe '.search_by_keyword' do
      let(:user) { create(:user) }
      let!(:mansion_dream) { create(:dream, user: user, title: '古びた洋館', content: '地下室の奥で') }
      let!(:forest_dream) { create(:dream, user: user, title: '森の記憶', content: '木陰で休む') }
      let!(:library_dream) { create(:dream, user: user, title: '静かな図書館', content: '古びた本を探す') }

      it 'titleのみでキーワード検索できる' do
        result = described_class.search_by_keyword('洋館')
        expect(result).to include(mansion_dream)
        expect(result).not_to include(forest_dream, library_dream)
      end

      it 'contentのみでキーワード検索できる' do
        result = described_class.search_by_keyword('地下室')
        expect(result).to include(mansion_dream)
        expect(result).not_to include(forest_dream, library_dream)
      end

      it 'title と content 両方でキーワード検索できる（OR条件）' do
        result = described_class.search_by_keyword('古びた')
        expect(result).to include(mansion_dream, library_dream) # mansion_dreamはtitle、library_dreamはcontentでヒット
        expect(result).not_to include(forest_dream)
      end

      it 'どちらにもマッチしない場合は結果が空' do
        result = described_class.search_by_keyword('存在しない')
        expect(result).to be_empty
      end

      it 'キーワードが空の場合は全件返す' do
        expect(described_class.search_by_keyword('')).to include(mansion_dream, forest_dream, library_dream)
      end

      it 'キーワードがnilの場合は全件返す' do
        expect(described_class.search_by_keyword(nil)).to include(mansion_dream, forest_dream, library_dream)
      end
    end

    describe '.tagged_with' do
      let(:user) { create(:user) }
      let(:person_tag) { create(:tag, name: '太郎', user: user) }
      let(:place_tag) { create(:tag, name: '洋館', user: user) }
      let!(:tagged_dream_with_both) { create(:dream, user: user, tags: [person_tag, place_tag]) }
      let!(:tagged_dream_with_person) { create(:dream, user: user, tags: [person_tag]) }

      it '指定したタグを全て持つ夢のみ返す（AND条件）' do
        result = described_class.tagged_with([person_tag.id, place_tag.id])
        expect(result).to include(tagged_dream_with_both)
        expect(result).not_to include(tagged_dream_with_person)
      end

      it 'タグIDが空配列の場合は全件返す' do
        expect(described_class.tagged_with([])).to include(tagged_dream_with_both, tagged_dream_with_person)
      end

      it 'タグIDがnilの場合は全件返す' do
        expect(described_class.tagged_with(nil)).to include(tagged_dream_with_both, tagged_dream_with_person)
      end
    end
  end

  # ========================================
  # コールバック・デフォルト値
  # ========================================
  describe 'コールバックとデフォルト値' do
    describe 'lucid_dream_flagのデフォルト値' do
      let(:dream) { create(:dream) }

      it 'デフォルトでfalseになる' do
        expect(dream.lucid_dream_flag).to be(false)
      end
    end

    describe 'sanitize_contentコールバック' do
      let(:dream) { create(:dream, content: '<script>alert("XSS")</script>安全なテキスト') }

      it 'contentからHTMLタグを除去する' do
        expect(dream.content).not_to include('<script>')
        expect(dream.content).to include('安全なテキスト')
      end

      it 'contentから属性を除去する' do
        dream_with_attrs = create(:dream, content: '<p onclick="alert()">テキスト</p>')
        expect(dream_with_attrs.content).not_to include('onclick')
        expect(dream_with_attrs.content).to include('テキスト')
      end
    end
  end
end
