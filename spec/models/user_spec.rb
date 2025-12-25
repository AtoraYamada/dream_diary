# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  username               :string           not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_username              (username) UNIQUE
#
require 'rails_helper'

RSpec.describe User, type: :model do
  subject { build(:user) }

  # ========================================
  # アソシエーション
  # ========================================
  describe 'アソシエーション' do
    it { is_expected.to have_many(:dreams).dependent(:destroy) }
    it { is_expected.to have_many(:tags).dependent(:destroy) }
  end

  # ========================================
  # バリデーション
  # ========================================
  describe 'バリデーション' do
    # shoulda-matchers による基本テスト
    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:password) }

    # --- 正常系 ---
    describe '正常系' do
      context '全ての必須項目が正しく入力されている場合' do
        let(:user) { build(:user) }

        it 'バリデーションが通る' do
          expect(user).to be_valid
        end
      end

      context 'passwordが6文字の場合' do
        let(:user) { build(:user, password: 'abc123', password_confirmation: 'abc123') }

        it 'バリデーションが通る' do
          expect(user).to be_valid
        end
      end
    end

    # --- 異常系 ---
    describe '異常系' do
      context 'usernameがnilの場合' do
        let(:user) { build(:user, username: nil) }

        it 'バリデーションエラーが発生する' do
          expect(user).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          user.valid?
          expect(user.errors.full_messages_for(:username)).to eq(['利用者名 が記された形跡がありません'])
        end
      end

      context 'usernameが空文字の場合' do
        let(:user) { build(:user, username: '') }

        it 'バリデーションエラーが発生する' do
          expect(user).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          user.valid?
          expect(user.errors.full_messages_for(:username)).to eq(['利用者名 が記された形跡がありません'])
        end
      end

      context 'usernameが既に存在する場合' do
        let!(:existing_user) { create(:user, username: 'testuser') }
        let(:duplicate_user) { build(:user, username: 'testuser') }

        it 'バリデーションエラーが発生する' do
          expect(duplicate_user).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          duplicate_user.valid?
          expect(duplicate_user.errors.full_messages_for(:username)).to eq(['利用者名 は既に蔵書目録に刻まれています'])
        end
      end

      context 'emailがnilの場合' do
        let(:user) { build(:user, email: nil) }

        it 'バリデーションエラーが発生する' do
          expect(user).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          user.valid?
          expect(user.errors.full_messages_for(:email)).to eq(['連絡の灯火 が灯されておりません'])
        end
      end

      context 'emailが空文字の場合' do
        let(:user) { build(:user, email: '') }

        it 'バリデーションエラーが発生する' do
          expect(user).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          user.valid?
          expect(user.errors.full_messages_for(:email)).to eq(['連絡の灯火 が灯されておりません'])
        end
      end

      context 'emailが既に存在する場合' do
        let!(:existing_user) { create(:user, email: 'test@example.com') }
        let(:duplicate_user) { build(:user, email: 'test@example.com') }

        it 'バリデーションエラーが発生する' do
          expect(duplicate_user).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          duplicate_user.valid?
          expect(duplicate_user.errors.full_messages_for(:email)).to eq(['連絡の灯火 は別の場所で灯っているようです'])
        end
      end

      context 'emailが不正な形式の場合' do
        let(:user) { build(:user, email: 'invalid-email') }

        it 'バリデーションエラーが発生する' do
          expect(user).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          user.valid?
          expect(user.errors.full_messages_for(:email)).to eq(['連絡の灯火 に必要な「印」が刻まれていません'])
        end
      end

      context 'passwordがnilの場合' do
        let(:user) { build(:user, password: nil, password_confirmation: nil) }

        it 'バリデーションエラーが発生する' do
          expect(user).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          user.valid?
          expect(user.errors.full_messages_for(:password)).to eq(['記憶の鍵 を携えていないようです'])
        end
      end

      context 'passwordが空文字の場合' do
        let(:user) { build(:user, password: '', password_confirmation: '') }

        it 'バリデーションエラーが発生する' do
          expect(user).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          user.valid?
          expect(user.errors.full_messages_for(:password)).to eq(['記憶の鍵 を携えていないようです'])
        end
      end

      context 'password_confirmationが一致しない場合' do
        let(:user) { build(:user, password: 'password123', password_confirmation: 'different') }

        it 'バリデーションエラーが発生する' do
          expect(user).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          user.valid?
          expect(user.errors.full_messages_for(:password_confirmation)).to eq(['2本目の記憶の鍵 と1本目の記憶の鍵が一致しません'])
        end
      end
    end

    # --- 境界系 ---
    describe '境界系' do
      context 'passwordが5文字の場合' do
        let(:user) { build(:user, password: 'abc12', password_confirmation: 'abc12') }

        it 'バリデーションエラーが発生する' do
          expect(user).to be_invalid
        end

        it 'カスタムエラーメッセージが表示される' do
          user.valid?
          expect(user.errors.full_messages_for(:password)).to eq(['記憶の鍵 の強度が足りません（最小6文字）'])
        end
      end
    end
  end
end
