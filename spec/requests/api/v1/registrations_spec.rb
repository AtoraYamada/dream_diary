require 'rails_helper'

RSpec.describe 'Api::V1::Registrations', type: :request do
  # CSRFトークン取得ヘルパー
  def fetch_csrf_token
    get '/api/v1/csrf'
    response.parsed_body['csrf_token']
  end

  describe 'POST /api/v1/registrations' do
    # --- 正常系 ---
    describe '正常系' do
      context '全ての必須項目が正しく入力されている場合' do
        it '新規ユーザーが作成され、カスタムメッセージが返る' do
          csrf_token = fetch_csrf_token

          expect do
            post '/api/v1/registrations', params: {
              user: {
                username: 'newuser',
                email: 'newuser@example.com',
                password: 'password123',
                password_confirmation: 'password123'
              }
            }, headers: { 'X-CSRF-Token' => csrf_token }
          end.to change(User, :count).by(1)

          expect(response).to have_http_status(:created)
          json = response.parsed_body
          expect(json['message']).to eq('入館の手続きが完了しました。貴方の筆録者としての歩みが始まります。')
          expect(json['user']).to include(
            'username' => 'newuser',
            'email' => 'newuser@example.com'
          )
          expect(json['user']).to have_key('id')
        end
      end
    end

    # --- 異常系 ---
    describe '異常系' do
      context 'usernameが重複している場合' do
        let!(:existing_user) { create(:user, username: 'existinguser') }

        it '422エラーとエラーメッセージが返る' do
          csrf_token = fetch_csrf_token

          post '/api/v1/registrations', params: {
            user: {
              username: 'existinguser',
              email: 'newuser@example.com',
              password: 'password123',
              password_confirmation: 'password123'
            }
          }, headers: { 'X-CSRF-Token' => csrf_token }

          expect(response).to have_http_status(:unprocessable_content)
          json = response.parsed_body
          expect(json).to have_key('errors')
          expect(json['errors']).to be_an(Array)
        end
      end

      context 'emailが重複している場合' do
        let!(:existing_user) { create(:user, email: 'existing@example.com') }

        it '422エラーとエラーメッセージが返る' do
          csrf_token = fetch_csrf_token

          post '/api/v1/registrations', params: {
            user: {
              username: 'newuser',
              email: 'existing@example.com',
              password: 'password123',
              password_confirmation: 'password123'
            }
          }, headers: { 'X-CSRF-Token' => csrf_token }

          expect(response).to have_http_status(:unprocessable_content)
          json = response.parsed_body
          expect(json).to have_key('errors')
          expect(json['errors']).to be_an(Array)
        end
      end

      context 'passwordが6文字未満の場合' do
        it '422エラーとエラーメッセージが返る' do
          csrf_token = fetch_csrf_token

          post '/api/v1/registrations', params: {
            user: {
              username: 'newuser',
              email: 'newuser@example.com',
              password: 'short',
              password_confirmation: 'short'
            }
          }, headers: { 'X-CSRF-Token' => csrf_token }

          expect(response).to have_http_status(:unprocessable_content)
          json = response.parsed_body
          expect(json).to have_key('errors')
          expect(json['errors']).to be_an(Array)
        end
      end

      context 'password_confirmationが一致しない場合' do
        it '422エラーとエラーメッセージが返る' do
          csrf_token = fetch_csrf_token

          post '/api/v1/registrations', params: {
            user: {
              username: 'newuser',
              email: 'newuser@example.com',
              password: 'password123',
              password_confirmation: 'different'
            }
          }, headers: { 'X-CSRF-Token' => csrf_token }

          expect(response).to have_http_status(:unprocessable_content)
          json = response.parsed_body
          expect(json).to have_key('errors')
          expect(json['errors']).to be_an(Array)
        end
      end

      context 'usernameが未入力の場合' do
        it '422エラーとエラーメッセージが返る' do
          csrf_token = fetch_csrf_token

          post '/api/v1/registrations', params: {
            user: {
              username: '',
              email: 'newuser@example.com',
              password: 'password123',
              password_confirmation: 'password123'
            }
          }, headers: { 'X-CSRF-Token' => csrf_token }

          expect(response).to have_http_status(:unprocessable_content)
          json = response.parsed_body
          expect(json).to have_key('errors')
          expect(json['errors']).to be_an(Array)
        end
      end

      context 'emailが未入力の場合' do
        it '422エラーとエラーメッセージが返る' do
          csrf_token = fetch_csrf_token

          post '/api/v1/registrations', params: {
            user: {
              username: 'newuser',
              email: '',
              password: 'password123',
              password_confirmation: 'password123'
            }
          }, headers: { 'X-CSRF-Token' => csrf_token }

          expect(response).to have_http_status(:unprocessable_content)
          json = response.parsed_body
          expect(json).to have_key('errors')
          expect(json['errors']).to be_an(Array)
        end
      end

      context 'passwordが未入力の場合' do
        it '422エラーとエラーメッセージが返る' do
          csrf_token = fetch_csrf_token

          post '/api/v1/registrations', params: {
            user: {
              username: 'newuser',
              email: 'newuser@example.com',
              password: '',
              password_confirmation: ''
            }
          }, headers: { 'X-CSRF-Token' => csrf_token }

          expect(response).to have_http_status(:unprocessable_content)
          json = response.parsed_body
          expect(json).to have_key('errors')
          expect(json['errors']).to be_an(Array)
        end
      end

      context 'emailが不正な形式の場合' do
        it '422エラーとエラーメッセージが返る' do
          csrf_token = fetch_csrf_token

          post '/api/v1/registrations', params: {
            user: {
              username: 'newuser',
              email: 'invalid-email',
              password: 'password123',
              password_confirmation: 'password123'
            }
          }, headers: { 'X-CSRF-Token' => csrf_token }

          expect(response).to have_http_status(:unprocessable_content)
          json = response.parsed_body
          expect(json).to have_key('errors')
          expect(json['errors']).to be_an(Array)
        end
      end

      context 'CSRFトークンがない場合' do
        it '403エラーが返る' do
          post '/api/v1/registrations', params: {
            user: {
              username: 'newuser',
              email: 'newuser@example.com',
              password: 'password123',
              password_confirmation: 'password123'
            }
          }

          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end
end
