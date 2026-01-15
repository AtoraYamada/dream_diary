require 'rails_helper'

RSpec.describe 'Api::V1::Sessions', type: :request do
  # ファクトリのsequenceを使用（重複を避けるため）
  let(:user) { create(:user, password: 'password123') }

  # CSRFトークン取得ヘルパー
  def fetch_csrf_token
    get '/api/v1/csrf'
    response.parsed_body['csrf_token']
  end

  describe 'POST /api/v1/sessions' do
    # --- 正常系 ---
    describe '正常系' do
      context 'emailでログインする場合' do
        it 'ログインが成功し、カスタムメッセージが返る' do
          csrf_token = fetch_csrf_token

          post '/api/v1/sessions', params: {
            user: {
              login: user.email,
              password: 'password123'
            }
          }, headers: { 'X-CSRF-Token' => csrf_token }

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['message']).to eq('記憶の鍵が噛み合い、閉ざされていた書斎の扉が開きました。')
          expect(json['user']).to include(
            'id' => user.id,
            'email' => user.email,
            'username' => user.username
          )
        end
      end

      context 'usernameでログインする場合' do
        it 'ログインが成功し、カスタムメッセージが返る' do
          csrf_token = fetch_csrf_token

          post '/api/v1/sessions', params: {
            user: {
              login: user.username,
              password: 'password123'
            }
          }, headers: { 'X-CSRF-Token' => csrf_token }

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['message']).to eq('記憶の鍵が噛み合い、閉ざされていた書斎の扉が開きました。')
          expect(json['user']).to include(
            'id' => user.id,
            'email' => user.email,
            'username' => user.username
          )
        end
      end
    end

    # --- 異常系 ---
    describe '異常系' do
      context 'パスワードが誤っている場合' do
        it '401エラーが返る' do
          csrf_token = fetch_csrf_token

          post '/api/v1/sessions', params: {
            user: {
              login: user.email,
              password: 'wrongpassword'
            }
          }, headers: { 'X-CSRF-Token' => csrf_token }

          expect(response).to have_http_status(:unauthorized)
          json = response.parsed_body
          expect(json).to have_key('error')
        end
      end

      context '存在しないユーザーでログインする場合' do
        it '401エラーが返る' do
          csrf_token = fetch_csrf_token

          post '/api/v1/sessions', params: {
            user: {
              login: 'nonexistent@example.com',
              password: 'password123'
            }
          }, headers: { 'X-CSRF-Token' => csrf_token }

          expect(response).to have_http_status(:unauthorized)
          json = response.parsed_body
          expect(json).to have_key('error')
        end
      end

      context 'CSRFトークンがない場合' do
        it '403エラーが返る' do
          post '/api/v1/sessions', params: {
            user: {
              login: user.email,
              password: 'password123'
            }
          }

          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end

  describe 'DELETE /api/v1/sessions' do
    # --- 正常系 ---
    describe '正常系' do
      context 'ログイン中の場合' do
        it 'ログアウトが成功し、カスタムメッセージが返る' do
          # ① CSRFトークン取得
          csrf_token = fetch_csrf_token

          # ② ログインAPI実行
          post '/api/v1/sessions', params: {
            user: {
              login: user.email,
              password: 'password123'
            }
          }, headers: { 'X-CSRF-Token' => csrf_token }

          expect(response).to have_http_status(:ok)

          # ③ ログイン後のCSRFトークン取得（ログイン後にトークンがリフレッシュされるため）
          csrf_token = fetch_csrf_token

          # ④ ログアウトAPI実行
          delete '/api/v1/sessions', headers: { 'X-CSRF-Token' => csrf_token }

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['message']).to eq('記録の筆を置きました。夢の続きは、また次の眠りの果てに。')
        end
      end

      context '既にログアウト済みの場合' do
        it '401エラーとカスタムメッセージが返る' do
          csrf_token = fetch_csrf_token

          delete '/api/v1/sessions', headers: { 'X-CSRF-Token' => csrf_token }

          expect(response).to have_http_status(:unauthorized)
          json = response.parsed_body
          expect(json['error']).to eq('既に目覚めています。ここには貴方の影すら残っていません')
        end
      end
    end

    # --- 異常系 ---
    describe '異常系' do
      context 'CSRFトークンがない場合' do
        it '403エラーが返る' do
          # CSRFトークン取得してログイン
          csrf_token = fetch_csrf_token
          post '/api/v1/sessions', params: {
            user: {
              login: user.email,
              password: 'password123'
            }
          }, headers: { 'X-CSRF-Token' => csrf_token }

          # CSRFトークンなしでログアウト試行
          delete '/api/v1/sessions'

          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end
end
