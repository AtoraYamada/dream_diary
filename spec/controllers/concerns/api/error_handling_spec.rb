require 'rails_helper'

RSpec.describe Api::ErrorHandling, type: :controller do
  # テスト用のダミーコントローラーを定義
  controller(ActionController::API) do
    include Api::ErrorHandling # rubocop:disable RSpec/DescribedClass

    def not_found_action
      raise ActiveRecord::RecordNotFound
    end

    def invalid_action
      user = User.new # 無効なユーザー（バリデーションエラー）
      user.save!
    end
  end

  before do
    routes.draw do
      get 'not_found_action' => 'anonymous#not_found_action'
      get 'invalid_action' => 'anonymous#invalid_action'
    end
  end

  describe '#render_not_found' do
    it 'ActiveRecord::RecordNotFound をキャッチして 404 を返すこと' do
      get :not_found_action

      expect(response).to have_http_status(:not_found)
      json = response.parsed_body
      expect(json['error']).to eq('Not Found')
      expect(json['message']).to eq('お探しのものは、ここには無いようです')
    end
  end

  describe '#render_unprocessable_content' do
    it 'ActiveRecord::RecordInvalid をキャッチして 422 を返すこと' do
      get :invalid_action

      expect(response).to have_http_status(:unprocessable_content)
      json = response.parsed_body
      expect(json['errors']).to be_an(Array)
      expect(json['errors']).not_to be_empty
    end
  end
end
