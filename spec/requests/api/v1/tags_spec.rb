require 'rails_helper'

RSpec.describe 'Api::V1::Tags', type: :request do
  let(:user) { create(:user, password: 'password123') }
  let(:other_user) { create(:user) }

  # CSRFトークン取得ヘルパー
  def fetch_csrf_token
    get root_path
    Nokogiri::HTML(response.body).at('meta[name="csrf-token"]')['content']
  end

  # ログインヘルパー
  def api_login(user)
    csrf_token = fetch_csrf_token
    post '/api/v1/sessions', params: {
      user: {
        login: user.email,
        password: 'password123'
      }
    }, headers: { 'X-CSRF-Token' => csrf_token }
    fetch_csrf_token # ログイン後のトークンを再取得
  end

  describe 'GET /api/v1/tags' do
    context '認証済みユーザーの場合' do
      before { api_login(user) }

      context 'タグが存在する場合' do
        let!(:person_tag1) { create(:tag, name: '太郎', yomi: 'たろう', category: :person, user: user) }
        let!(:person_tag2) { create(:tag, name: '花子', yomi: 'はなこ', category: :person, user: user) }
        let!(:place_tag) { create(:tag, name: '洋館', yomi: 'ようかん', category: :place, user: user) }
        let!(:other_user_tag) { create(:tag, user: other_user) }

        it '自分のタグ一覧を返すこと' do
          get '/api/v1/tags'

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['tags'].size).to eq(3)
          expect(json['tags'].first).to include('id', 'name', 'yomi', 'yomi_index', 'category')
          expect(json['tags'].first).not_to have_key('dream_count') # dream_countは削除済み
        end

        it '他ユーザーのタグは含まれないこと' do
          get '/api/v1/tags'

          json = response.parsed_body
          tag_ids = json['tags'].pluck('id')
          expect(tag_ids).not_to include(other_user_tag.id)
        end
      end

      context 'categoryフィルタ' do
        let!(:person_tag) { create(:tag, name: '太郎', yomi: 'たろう', category: :person, user: user) }
        let!(:place_tag) { create(:tag, name: '洋館', yomi: 'ようかん', category: :place, user: user) }

        it 'person カテゴリでフィルタできること' do
          get '/api/v1/tags', params: { category: 'person' }

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['tags'].size).to eq(1)
          expect(json['tags'].first['id']).to eq(person_tag.id)
          expect(json['tags'].first['category']).to eq('person')
        end

        it 'place カテゴリでフィルタできること' do
          get '/api/v1/tags', params: { category: 'place' }

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['tags'].size).to eq(1)
          expect(json['tags'].first['id']).to eq(place_tag.id)
          expect(json['tags'].first['category']).to eq('place')
        end
      end

      context 'yomi_indexフィルタ' do
        let!(:ta_tag) { create(:tag, name: '太郎', yomi: 'たろう', category: :person, user: user) }
        let!(:ha_tag) { create(:tag, name: '花子', yomi: 'はなこ', category: :person, user: user) }

        it 'yomi_index でフィルタできること' do
          get '/api/v1/tags', params: { yomi_index: 'た' }

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['tags'].size).to eq(1)
          expect(json['tags'].first['id']).to eq(ta_tag.id)
          expect(json['tags'].first['yomi_index']).to eq('た')
        end
      end

      context 'category と yomi_index を組み合わせてフィルタ' do
        let!(:person_ta_tag) { create(:tag, name: '太郎', yomi: 'たろう', category: :person, user: user) }
        let!(:place_ta_tag) { create(:tag, name: '竹林', yomi: 'たけばやし', category: :place, user: user) }

        it '両方の条件を満たすタグのみ返すこと' do
          get '/api/v1/tags', params: { category: 'person', yomi_index: 'た' }

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['tags'].size).to eq(1)
          expect(json['tags'].first['id']).to eq(person_ta_tag.id)
        end
      end

      context 'タグが存在しない場合' do
        it '空の配列を返すこと' do
          get '/api/v1/tags'

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['tags']).to eq([])
        end
      end
    end

    context '未認証ユーザーの場合' do
      it '401を返すこと' do
        get '/api/v1/tags'

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/tags/suggest' do
    context '認証済みユーザーの場合' do
      before { api_login(user) }

      context 'name での検索' do
        let!(:taro_tag) { create(:tag, name: '太郎', yomi: 'たろう', category: :person, user: user) }
        let!(:taiko_tag) { create(:tag, name: '太鼓', yomi: 'たいこ', category: :place, user: user) }
        let!(:hanako_tag) { create(:tag, name: '花子', yomi: 'はなこ', category: :person, user: user) }

        it 'name で部分一致検索できること' do
          get '/api/v1/tags/suggest', params: { query: '太' }

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['suggestions'].size).to eq(2)
          tag_ids = json['suggestions'].pluck('id')
          expect(tag_ids).to contain_exactly(taro_tag.id, taiko_tag.id)
        end

        it '完全一致でも検索できること' do
          get '/api/v1/tags/suggest', params: { query: '太郎' }

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['suggestions'].size).to eq(1)
          expect(json['suggestions'].first['id']).to eq(taro_tag.id)
        end
      end

      context 'yomi での検索' do
        let!(:taro_tag) { create(:tag, name: '太郎', yomi: 'たろう', category: :person, user: user) }
        let!(:taiko_tag) { create(:tag, name: '太鼓', yomi: 'たいこ', category: :place, user: user) }

        it 'yomi で部分一致検索できること' do
          get '/api/v1/tags/suggest', params: { query: 'たろ' }

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['suggestions'].size).to eq(1)
          expect(json['suggestions'].first['id']).to eq(taro_tag.id)
        end
      end

      context 'category フィルタとの組み合わせ' do
        let!(:person_tag) { create(:tag, name: '太郎', yomi: 'たろう', category: :person, user: user) }
        let!(:place_tag) { create(:tag, name: '太陽', yomi: 'たいよう', category: :place, user: user) }

        it 'category でフィルタできること' do
          get '/api/v1/tags/suggest', params: { query: '太', category: 'person' }

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['suggestions'].size).to eq(1)
          expect(json['suggestions'].first['id']).to eq(person_tag.id)
          expect(json['suggestions'].first['category']).to eq('person')
        end
      end

      context '最大10件まで返すこと' do
        let!(:tags) { create_list(:tag, 15, user: user, yomi: 'たぐ') }

        it '10件のみ返すこと' do
          get '/api/v1/tags/suggest', params: { query: 'たぐ' }

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['suggestions'].size).to eq(10)
        end
      end

      context 'レスポンス形式の検証' do
        let!(:tag) { create(:tag, name: '太郎', yomi: 'たろう', category: :person, user: user) }

        it 'id, name, yomi, category を含むこと' do
          get '/api/v1/tags/suggest', params: { query: '太郎' }

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          suggestion = json['suggestions'].first
          expect(suggestion).to include(
            'id' => tag.id,
            'name' => '太郎',
            'yomi' => 'たろう',
            'category' => 'person'
          )
          expect(suggestion).not_to have_key('yomi_index')
        end
      end

      context '検索結果が0件の場合' do
        it '空の配列を返すこと' do
          get '/api/v1/tags/suggest', params: { query: '存在しないタグ' }

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['suggestions']).to eq([])
        end
      end
    end

    context '未認証ユーザーの場合' do
      it '401を返すこと' do
        get '/api/v1/tags/suggest', params: { query: 'test' }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/tags/:id' do
    let!(:tag) { create(:tag, user: user) }
    let(:csrf_token) { api_login(user) }

    context '認証済みユーザーの場合' do
      it 'タグを削除できること' do
        expect do
          delete "/api/v1/tags/#{tag.id}", headers: { 'X-CSRF-Token' => csrf_token }
        end.to change(Tag, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      context '存在しないタグの場合' do
        it '404を返すこと' do
          delete '/api/v1/tags/99999', headers: { 'X-CSRF-Token' => csrf_token }

          expect(response).to have_http_status(:not_found)
        end
      end

      context '他ユーザーのタグを削除しようとした場合' do
        let(:other_tag) { create(:tag, user: other_user) }

        it '404を返すこと' do
          delete "/api/v1/tags/#{other_tag.id}", headers: { 'X-CSRF-Token' => csrf_token }

          expect(response).to have_http_status(:not_found)
        end
      end

      context 'CSRFトークンがない場合' do
        it '403エラーが返る' do
          api_login(user)
          delete "/api/v1/tags/#{tag.id}"

          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context '未認証ユーザーの場合' do
      it '401を返すこと' do
        csrf_token = fetch_csrf_token
        delete "/api/v1/tags/#{tag.id}", headers: { 'X-CSRF-Token' => csrf_token }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
