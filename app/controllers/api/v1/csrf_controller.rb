class Api::V1::CsrfController < ActionController::Base
  # NOTE: トークン取得エンドポイントでCSRF検証すると無限ループになるためスキップ
  skip_before_action :verify_authenticity_token, only: [:show]

  def show
    render json: { csrf_token: form_authenticity_token }
  end
end
