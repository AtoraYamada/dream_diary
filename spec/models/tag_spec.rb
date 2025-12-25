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
require 'rails_helper'

RSpec.describe Tag, type: :model do
  subject { build(:tag) }

  # ========================================
  # アソシエーション
  # ========================================
  describe 'アソシエーション' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:dream_tags).dependent(:destroy) }
    it { is_expected.to have_many(:dreams).through(:dream_tags) }
  end

  # ========================================
  # バリデーション
  # ========================================
  describe 'バリデーション' do
    # shoulda-matchers による基本テスト
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:yomi) }
    it { is_expected.to validate_presence_of(:category) }
    it { is_expected.to validate_presence_of(:yomi_index) }

    # --- 正常系 ---
    describe '正常系' do
      context '全ての必須項目が正しく入力されている場合' do
        let(:tag) { build(:tag) }

        it 'バリデーションが通る' do
          expect(tag).to be_valid
        end
      end

      context '同じユーザーで異なるnameの場合' do
        let(:user) { create(:user) }
        let!(:tag1) { create(:tag, user: user, name: '太郎') }
        let(:tag2) { build(:tag, user: user, name: '次郎') }

        it 'バリデーションが通る' do
          expect(tag2).to be_valid
        end
      end

      context '異なるユーザーで同じnameの場合' do
        let(:user1) { create(:user) }
        let(:user2) { create(:user) }
        let!(:tag1) { create(:tag, user: user1, name: '太郎') }
        let(:tag2) { build(:tag, user: user2, name: '太郎') }

        it 'バリデーションが通る（ユーザー毎にスコープされている）' do
          expect(tag2).to be_valid
        end
      end
    end

    # --- 異常系 ---
    describe '異常系' do
      context 'nameがnilの場合' do
        let(:tag) { build(:tag, name: nil) }

        it 'バリデーションエラーが発生する' do
          expect(tag).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          tag.valid?
          expect(tag.errors.full_messages_for(:name)).to eq(['栞の銘 が記された形跡がありません'])
        end
      end

      context 'nameが空文字の場合' do
        let(:tag) { build(:tag, name: '') }

        it 'バリデーションエラーが発生する' do
          expect(tag).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          tag.valid?
          expect(tag.errors.full_messages_for(:name)).to eq(['栞の銘 が記された形跡がありません'])
        end
      end

      context 'yomiがnilの場合' do
        let(:tag) { build(:tag, yomi: nil) }

        it 'バリデーションエラーが発生する' do
          expect(tag).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される（yomiとyomi_index両方）' do
          tag.valid?
          expect(tag.errors.full_messages_for(:yomi)).to eq(['栞の読み が記された形跡がありません'])
          expect(tag.errors.full_messages_for(:yomi_index)).to eq(['栞の目録 が不明です'])
        end
      end

      context 'yomiが空文字の場合' do
        let(:tag) { build(:tag, yomi: '') }

        it 'バリデーションエラーが発生する' do
          expect(tag).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される（yomiとyomi_index両方）' do
          tag.valid?
          expect(tag.errors.full_messages_for(:yomi)).to eq(['栞の読み が記された形跡がありません'])
          expect(tag.errors.full_messages_for(:yomi_index)).to eq(['栞の目録 が不明です'])
        end
      end

      context 'categoryがnilの場合' do
        let(:tag) { build(:tag, category: nil) }

        it 'バリデーションエラーが発生する' do
          expect(tag).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          tag.valid?
          expect(tag.errors.full_messages_for(:category)).to eq(['栞の種別 が不明です'])
        end
      end

      context 'userが関連付けられていない場合' do
        let(:tag) { build(:tag, user: nil) }

        it 'バリデーションエラーが発生する' do
          expect(tag).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          tag.valid?
          expect(tag.errors.full_messages_for(:user)).to eq(['筆録者 が誰か不明です'])
        end
      end

      context '同じユーザーで同じnameが既に存在する場合' do
        let(:user) { create(:user) }
        let!(:tag1) { create(:tag, user: user, name: '太郎') }
        let(:tag2) { build(:tag, user: user, name: '太郎') }

        it 'バリデーションエラーが発生する' do
          expect(tag2).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          tag2.valid?
          expect(tag2.errors.full_messages_for(:name)).to eq(['栞の銘 は既に記されています'])
        end
      end
    end
  end

  # ========================================
  # enum
  # ========================================
  describe 'enum' do
    describe 'category' do
      it { is_expected.to define_enum_for(:category).with_values(person: 0, place: 1) }

      # --- 正常系 ---
      describe '正常系' do
        context '有効なcategory値を設定した場合' do
          let(:tag) { build(:tag, :place) }

          it '正しく設定される' do
            expect(tag.category).to eq('place')
          end
        end
      end

      # --- 異常系 ---
      describe '異常系' do
        context 'バリデーション時に範囲外の値が設定されている場合' do
          let(:tag) { build(:tag) }

          before do
            # enum setterをバイパスして不正な値を直接設定
            tag.save(validate: false)
            tag.update_column(:category, 999)
          end

          it 'バリデーションエラーが発生する' do
            expect(tag).to be_invalid
          end

          it 'inclusionエラーメッセージが表示される' do
            tag.valid?
            expect(tag.errors.full_messages_for(:category)).to eq(['栞の種別 の作法が異なっているようです'])
          end
        end
      end
    end

    describe 'yomi_index' do
      it do
        expect(subject).to define_enum_for(:yomi_index).with_values(
          'あ' => 0, 'か' => 1, 'さ' => 2, 'た' => 3, 'な' => 4,
          'は' => 5, 'ま' => 6, 'や' => 7, 'ら' => 8, 'わ' => 9,
          '英数字' => 10, '他' => 11
        )
      end

      # --- 正常系 ---
      describe '正常系' do
        context '有効なyomi_index値を設定した場合' do
          let(:tag) { build(:tag, :with_custom_yomi) }

          before do
            tag.valid? # コールバックを実行
          end

          it '正しく設定される' do
            expect(tag.yomi_index).to eq('か')
          end
        end
      end

      # --- 異常系 ---
      describe '異常系' do
        context 'バリデーション時に範囲外の値が設定されている場合' do
          let(:tag) { build(:tag) }

          before do
            # enum setterをバイパスして不正な値を直接設定
            tag.save(validate: false)
            tag.update_column(:yomi_index, 999)
          end

          it 'バリデーションエラーが発生する' do
            expect(tag).to be_invalid
          end

          it 'inclusionエラーメッセージが表示される' do
            tag.valid?
            expect(tag.errors.full_messages_for(:yomi_index)).to eq(['栞の目録 の作法が異なっているようです'])
          end
        end
      end
    end
  end

  # ========================================
  # スコープ
  # ========================================
  describe 'スコープ' do
    describe '.by_category' do
      let(:user) { create(:user) }
      let!(:person_tag) { create(:tag, user: user, category: :person) }
      let!(:place_tag) { create(:tag, :place, user: user) }

      it '指定したカテゴリでフィルタする' do
        expect(described_class.by_category(:person)).to include(person_tag)
        expect(described_class.by_category(:person)).not_to include(place_tag)
      end
    end

    describe '.by_yomi_index' do
      let(:user) { create(:user) }
      let!(:ta_row_tag) { create(:tag, user: user, yomi: 'たぐ') } # た行
      let!(:ka_row_tag) { create(:tag, user: user, yomi: 'かすたむ') } # か行

      before do
        ta_row_tag.valid? # コールバックでyomi_index設定
        ka_row_tag.valid?
      end

      it '指定したyomi_indexでフィルタする' do
        expect(described_class.by_yomi_index('た')).to include(ta_row_tag)
        expect(described_class.by_yomi_index('た')).not_to include(ka_row_tag)
      end
    end

    describe '.search_by_name_or_yomi' do
      let(:user) { create(:user) }
      let!(:mansion_tag) { create(:tag, user: user, name: '古びた洋館', yomi: 'ふるびたようかん') }
      let!(:forest_tag) { create(:tag, user: user, name: '森の記憶', yomi: 'もりのきおく') }
      let!(:book_tag) { create(:tag, user: user, name: '静かな場所', yomi: 'ふるいほん') }

      it 'nameのみでキーワード検索できる' do
        result = described_class.search_by_name_or_yomi('洋館')
        expect(result).to include(mansion_tag)
        expect(result).not_to include(forest_tag, book_tag)
      end

      it 'yomiのみでキーワード検索できる' do
        result = described_class.search_by_name_or_yomi('もり')
        expect(result).to include(forest_tag)
        expect(result).not_to include(mansion_tag, book_tag)
      end

      it 'name と yomi 両方でキーワード検索できる（OR条件）' do
        result = described_class.search_by_name_or_yomi('ふる')
        expect(result).to include(mansion_tag, book_tag) # mansion_tagはnameでヒット、book_tagはyomiでヒット
        expect(result).not_to include(forest_tag)
      end

      it 'どちらにもマッチしない場合は結果が空' do
        result = described_class.search_by_name_or_yomi('存在しない')
        expect(result).to be_empty
      end

      it 'キーワードが空の場合は全件返す' do
        expect(described_class.search_by_name_or_yomi('')).to include(mansion_tag, forest_tag, book_tag)
      end

      it 'キーワードがnilの場合は全件返す' do
        expect(described_class.search_by_name_or_yomi(nil)).to include(mansion_tag, forest_tag, book_tag)
      end
    end
  end

  # ========================================
  # コールバック
  # ========================================
  describe 'コールバック' do
    describe 'set_yomi_indexコールバック' do
      let(:user) { create(:user) }

      context 'yomiが「あ」行で始まる場合' do
        let(:tag) { build(:tag, user: user, yomi: 'うみ') }

        it 'yomi_indexが「あ」に設定される' do
          tag.valid?
          expect(tag.yomi_index).to eq('あ')
        end
      end

      context 'yomiが「か」行で始まる場合' do
        let(:tag) { build(:tag, user: user, yomi: 'くも') }

        it 'yomi_indexが「か」に設定される' do
          tag.valid?
          expect(tag.yomi_index).to eq('か')
        end
      end

      context 'yomiが「さ」行で始まる場合' do
        let(:tag) { build(:tag, user: user, yomi: 'すずめ') }

        it 'yomi_indexが「さ」に設定される' do
          tag.valid?
          expect(tag.yomi_index).to eq('さ')
        end
      end

      context 'yomiが「た」行で始まる場合' do
        let(:tag) { build(:tag, user: user, yomi: 'つき') }

        it 'yomi_indexが「た」に設定される' do
          tag.valid?
          expect(tag.yomi_index).to eq('た')
        end
      end

      context 'yomiが「な」行で始まる場合' do
        let(:tag) { build(:tag, user: user, yomi: 'ぬま') }

        it 'yomi_indexが「な」に設定される' do
          tag.valid?
          expect(tag.yomi_index).to eq('な')
        end
      end

      context 'yomiが「は」行で始まる場合' do
        let(:tag) { build(:tag, user: user, yomi: 'ふゆ') }

        it 'yomi_indexが「は」に設定される' do
          tag.valid?
          expect(tag.yomi_index).to eq('は')
        end
      end

      context 'yomiが「ま」行で始まる場合' do
        let(:tag) { build(:tag, user: user, yomi: 'むら') }

        it 'yomi_indexが「ま」に設定される' do
          tag.valid?
          expect(tag.yomi_index).to eq('ま')
        end
      end

      context 'yomiが「や」行で始まる場合' do
        let(:tag) { build(:tag, user: user, yomi: 'ゆめ') }

        it 'yomi_indexが「や」に設定される' do
          tag.valid?
          expect(tag.yomi_index).to eq('や')
        end
      end

      context 'yomiが「ら」行で始まる場合' do
        let(:tag) { build(:tag, user: user, yomi: 'るいじ') }

        it 'yomi_indexが「ら」に設定される' do
          tag.valid?
          expect(tag.yomi_index).to eq('ら')
        end
      end

      context 'yomiが「わ」行で始まる場合' do
        let(:tag) { build(:tag, user: user, yomi: 'をかし') }

        it 'yomi_indexが「わ」に設定される' do
          tag.valid?
          expect(tag.yomi_index).to eq('わ')
        end
      end

      context 'yomiが英数字で始まる場合' do
        let(:tag) { build(:tag, user: user, yomi: 'ABC123') }

        it 'yomi_indexが「英数字」に設定される' do
          tag.valid?
          expect(tag.yomi_index).to eq('英数字')
        end
      end

      context 'yomiがその他の文字で始まる場合' do
        let(:tag) { build(:tag, user: user, yomi: '!@#') }

        it 'yomi_indexが「他」に設定される' do
          tag.valid?
          expect(tag.yomi_index).to eq('他')
        end
      end
    end
  end
end
