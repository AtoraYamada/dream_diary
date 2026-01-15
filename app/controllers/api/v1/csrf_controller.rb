module Api
  module V1
    class CsrfController < ApplicationController
      # NOTE: トークン取得エンドポイントでCSRF検証すると無限ループになるためスキップ
      skip_before_action :verify_authenticity_token, only: [:show]

      def show
        render json: { csrf_token: form_authenticity_token }
      end
    end
  end
end
