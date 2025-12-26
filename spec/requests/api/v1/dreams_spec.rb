require 'rails_helper'

RSpec.describe 'Api::V1::Dreams', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe 'GET /api/v1/dreams' do
    context '認証済みユーザーの場合' do
      before { sign_in user }

      context '夢が存在する場合' do
        let!(:dreams) { create_list(:dream, 15, user: user) }
        let!(:other_user_dreams) { create_list(:dream, 3, user: other_user) }

        it '自分の夢一覧を返すこと' do
          get '/api/v1/dreams'

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['dreams'].size).to eq(12) # デフォルトは12件
          expect(json['dreams'].first).to include('id', 'title', 'emotion_color', 'dreamed_at', 'tags')
        end

        it 'ページネーションが機能すること' do
          get '/api/v1/dreams', params: { page: 2, per_page: 10 }

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['dreams'].size).to eq(5) # 15件中、2ページ目は5件
          expect(json['pagination']).to include(
            'current_page' => 2,
            'total_pages' => 2,
            'total_count' => 15,
            'per_page' => 10
          )
        end
      end

      context '最新の夢から順に返すこと' do
        let!(:older_dream) { create(:dream, user: user, dreamed_at: 2.days.ago) }
        let!(:recent_dream) { create(:dream, user: user, dreamed_at: 1.day.ago) }
        let!(:oldest_dream) { create(:dream, user: user, dreamed_at: 3.days.ago) }

        it 'dreamed_atの降順で返すこと' do
          get '/api/v1/dreams'

          json = response.parsed_body
          dream_ids = json['dreams'].pluck('id')
          expect(dream_ids).to eq([recent_dream.id, older_dream.id, oldest_dream.id])
        end
      end

      context 'タグ付きの夢が存在する場合' do
        let!(:dream_with_tags) { create(:dream, :with_tags, user: user) }

        it 'タグ情報が含まれること' do
          get '/api/v1/dreams'

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          dream = json['dreams'].first
          expect(dream['tags']).to be_an(Array)
          expect(dream['tags'].first).to include('id', 'name', 'category')
        end
      end

      context '夢が存在しない場合' do
        it '空の配列を返すこと' do
          get '/api/v1/dreams'

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['dreams']).to eq([])
        end
      end
    end

    context '未認証ユーザーの場合' do
      it '401を返すこと' do
        get '/api/v1/dreams'

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/dreams/:id' do
    let!(:dream) { create(:dream, :with_tags, user: user) }

    context '認証済みユーザーの場合' do
      before { sign_in user }

      it '夢の詳細を返すこと' do
        get "/api/v1/dreams/#{dream.id}"

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json).to include(
          'id' => dream.id,
          'title' => dream.title,
          'content' => dream.content,
          'emotion_color' => dream.emotion_color,
          'dreamed_at' => dream.dreamed_at.iso8601(3),
          'created_at' => dream.created_at.iso8601(3),
          'updated_at' => dream.updated_at.iso8601(3)
        )
        expect(json['tags']).to be_an(Array)
      end

      context '存在しない夢の場合' do
        it '404を返すこと' do
          get '/api/v1/dreams/99999'

          expect(response).to have_http_status(:not_found)
        end
      end

      context '他ユーザーの夢にアクセスした場合' do
        let(:other_dream) { create(:dream, user: other_user) }

        it '404を返すこと' do
          get "/api/v1/dreams/#{other_dream.id}"

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context '未認証ユーザーの場合' do
      it '401を返すこと' do
        get "/api/v1/dreams/#{dream.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/dreams' do
    context '認証済みユーザーの場合' do
      before { sign_in user }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            dream: {
              title: '古びた洋館の夢',
              content: '夢の内容が記述されます。',
              emotion_color: 'peace',
              dreamed_at: Time.current.iso8601,
              lucid_dream_flag: false
            }
          }
        end

        it '夢を作成できること' do
          expect do
            post '/api/v1/dreams', params: valid_params
          end.to change(Dream, :count).by(1)

          expect(response).to have_http_status(:created)
          json = response.parsed_body
          expect(json).to include(
            'title' => '古びた洋館の夢',
            'content' => '夢の内容が記述されます。',
            'emotion_color' => 'peace'
          )
        end

        context 'タグなしの場合' do
          it '夢を作成できること' do
            expect do
              post '/api/v1/dreams', params: valid_params
            end.to change(Dream, :count).by(1)

            expect(response).to have_http_status(:created)
          end
        end

        context 'タグありの場合' do
          let(:params_with_tags) do
            valid_params.merge(
              dream: valid_params[:dream].merge(
                tag_attributes: [
                  { name: '太郎', yomi: 'たろう', category: 'person' },
                  { name: '古びた洋館', yomi: 'ふるびたようかん', category: 'place' }
                ]
              )
            )
          end

          it 'タグを同時作成・関連付けできること' do
            expect do
              post '/api/v1/dreams', params: params_with_tags
            end.to change(Dream, :count).by(1).and change(Tag, :count).by(2)

            expect(response).to have_http_status(:created)
            json = response.parsed_body
            expect(json['tags'].size).to eq(2)
          end
        end

        context 'lucid_dream_flagがtrueの場合' do
          let(:lucid_params) do
            valid_params.merge(
              dream: valid_params[:dream].merge(lucid_dream_flag: true)
            )
          end

          it '明晰夢として作成できること' do
            post '/api/v1/dreams', params: lucid_params

            expect(response).to have_http_status(:created)
            created_dream = Dream.last
            expect(created_dream.lucid_dream_flag).to be(true)
          end
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            dream: {
              title: '',
              content: '夢の内容',
              emotion_color: 'peace',
              dreamed_at: Time.current.iso8601
            }
          }
        end

        it '422を返すこと' do
          post '/api/v1/dreams', params: invalid_params

          expect(response).to have_http_status(:unprocessable_content)
          json = response.parsed_body
          expect(json).to have_key('errors')
        end
      end
    end

    context '未認証ユーザーの場合' do
      it '401を返すこと' do
        post '/api/v1/dreams', params: { dream: { title: 'test' } }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /api/v1/dreams/:id' do
    context '認証済みユーザーの場合' do
      before { sign_in user }

      context '有効なパラメータの場合' do
        let!(:existing_tag) { create(:tag, name: '既存タグ', yomi: 'きぞんたぐ', user: user) }
        let!(:dream_with_tag) do
          dream = create(:dream, user: user)
          dream.tags << existing_tag
          dream
        end

        let(:valid_params) do
          {
            dream: {
              title: '更新されたタイトル',
              content: '更新された内容',
              emotion_color: 'chaos',
              dreamed_at: Time.current.iso8601,
              lucid_dream_flag: true
            }
          }
        end

        it '夢を更新できること' do
          put "/api/v1/dreams/#{dream_with_tag.id}", params: valid_params

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json).to include(
            'title' => '更新されたタイトル',
            'content' => '更新された内容',
            'emotion_color' => 'chaos'
          )
        end

        context 'タグを追加する場合' do
          let(:params_with_new_tag) do
            valid_params.merge(
              dream: valid_params[:dream].merge(
                tag_attributes: [
                  { name: '既存タグ', yomi: 'きぞんたぐ', category: 'person' },
                  { name: '新しいタグ', yomi: 'あたらしいたぐ', category: 'person' }
                ]
              )
            )
          end

          it 'タグを追加できること' do
            expect do
              put "/api/v1/dreams/#{dream_with_tag.id}", params: params_with_new_tag
            end.to change(Tag, :count).by(1)

            expect(response).to have_http_status(:ok)
            json = response.parsed_body
            expect(json['tags'].size).to eq(2)
            tag_names = json['tags'].pluck('name')
            expect(tag_names).to contain_exactly('既存タグ', '新しいタグ')
          end
        end

        context 'タグを削除する場合（tag_attributesから除外）' do
          let(:params_without_tag) do
            valid_params.merge(
              dream: valid_params[:dream].merge(tag_attributes: [])
            )
          end

          it 'タグを削除できること' do
            put "/api/v1/dreams/#{dream_with_tag.id}", params: params_without_tag

            expect(response).to have_http_status(:ok)
            json = response.parsed_body
            expect(json['tags']).to be_empty
          end
        end
      end

      context '無効なパラメータの場合' do
        let!(:dream) { create(:dream, user: user) }
        let(:invalid_params) do
          {
            dream: {
              title: '',
              content: '内容'
            }
          }
        end

        it '422を返すこと' do
          put "/api/v1/dreams/#{dream.id}", params: invalid_params

          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context '存在しない夢の場合' do
        it '404を返すこと' do
          put '/api/v1/dreams/99999', params: { dream: { title: 'test' } }

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context '未認証ユーザーの場合' do
      let!(:dream) { create(:dream, user: user) }

      it '401を返すこと' do
        put "/api/v1/dreams/#{dream.id}", params: { dream: { title: 'test' } }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/dreams/:id' do
    let!(:dream) { create(:dream, user: user) }

    context '認証済みユーザーの場合' do
      before { sign_in user }

      it '夢を削除できること' do
        expect do
          delete "/api/v1/dreams/#{dream.id}"
        end.to change(Dream, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      context '存在しない夢の場合' do
        it '404を返すこと' do
          delete '/api/v1/dreams/99999'

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context '未認証ユーザーの場合' do
      it '401を返すこと' do
        delete "/api/v1/dreams/#{dream.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/dreams/search' do
    let!(:mansion_dream) { create(:dream, title: '古びた洋館', content: '太郎が登場', user: user) }
    let!(:forest_dream) { create(:dream, title: '森の中', content: '花子が歌う', user: user) }
    let!(:seaside_dream) { create(:dream, title: '海辺の町', content: '太郎と花子', user: user) }

    context '認証済みユーザーの場合' do
      before { sign_in user }

      context 'キーワード検索' do
        it 'タイトルで検索できること' do
          get '/api/v1/dreams/search', params: { keywords: '洋館' }

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['dreams'].size).to eq(1)
          dream_ids = json['dreams'].pluck('id')
          expect(dream_ids).to include(mansion_dream.id)
        end

        it '本文で検索できること' do
          get '/api/v1/dreams/search', params: { keywords: '太郎' }

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['dreams'].size).to eq(2)
          dream_ids = json['dreams'].pluck('id')
          expect(dream_ids).to contain_exactly(mansion_dream.id, seaside_dream.id)
        end
      end

      context 'タグ検索（AND条件）' do
        let!(:person_tag) { create(:tag, name: '太郎', yomi: 'たろう', user: user) }
        let!(:place_tag) { create(:tag, name: '洋館', yomi: 'ようかん', user: user) }
        let!(:tagged_dream_with_both) do
          dream = create(:dream, user: user)
          dream.tags << [person_tag, place_tag]
          dream
        end
        let!(:tagged_dream_with_person) do
          dream = create(:dream, user: user)
          dream.tags << person_tag
          dream
        end

        it '指定したタグを全て持つ夢のみ返すこと（AND条件）' do
          get '/api/v1/dreams/search', params: { tag_ids: "#{person_tag.id},#{place_tag.id}" }

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['dreams'].size).to eq(1)
          expect(json['dreams'].first['id']).to eq(tagged_dream_with_both.id)
        end
      end

      context 'キーワード + タグ検索' do
        let!(:tag) { create(:tag, user: user) }
        let!(:complex_dream) do
          dream = create(:dream, title: '複合検索', content: '複合検索のテスト', user: user)
          dream.tags << tag
          dream
        end

        it '複合検索ができること' do
          get '/api/v1/dreams/search', params: { keywords: '複合', tag_ids: tag.id.to_s }

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['dreams'].size).to eq(1)
          expect(json['dreams'].first['id']).to eq(complex_dream.id)
        end
      end
    end

    context '未認証ユーザーの場合' do
      it '401を返すこと' do
        get '/api/v1/dreams/search', params: { keywords: 'test' }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/dreams/overflow' do
    # 仕様書のフォールバックフラグメント
    let(:fallback_fragments) do
      [
        '遠くで鐘が鳴っている',
        '鍵は開いたままだ',
        '古びた本棚に埃が積もっている',
        '森の奥から誰かが呼んでいる',
        '月が二つ見える',
        '時計の針が逆回りしている',
        '窓の外に誰かの影が見える'
      ]
    end

    context '認証済みユーザーの場合' do
      before { sign_in user }

      context '夢が十分に存在する場合' do
        let!(:dreams) do
          create_list(:dream, 10, user: user, content: '文章1。文章2。文章3。文章4。文章5。')
        end

        it 'ランダムなフラグメント（5〜8個）を返すこと' do
          get '/api/v1/dreams/overflow'

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['fragments']).to be_an(Array)
          expect(json['fragments'].size).to be_between(5, 8)
          json['fragments'].each do |fragment|
            expect(fragment).to be_a(String)
            expect(fragment).not_to be_empty
          end
        end

        it 'システムフォールバックフラグメントが含まれていないこと' do
          get '/api/v1/dreams/overflow'

          json = response.parsed_body
          json['fragments'].each do |fragment|
            expect(fallback_fragments).not_to include(fragment)
          end
        end
      end

      context '夢が少ない場合' do
        let!(:dreams) { create_list(:dream, 2, user: user, content: '短い文章。') }

        it 'フォールバックフラグメントを含むこと' do
          get '/api/v1/dreams/overflow'

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json['fragments']).to be_an(Array)
          expect(json['fragments'].size).to be_between(5, 8)

          # 少なくとも1つのフォールバックフラグメントが含まれていること
          has_fallback = json['fragments'].any? { |fragment| fallback_fragments.include?(fragment) }
          expect(has_fallback).to be(true)
        end
      end
    end

    context '未認証ユーザーの場合' do
      it '401を返すこと' do
        get '/api/v1/dreams/overflow'

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
