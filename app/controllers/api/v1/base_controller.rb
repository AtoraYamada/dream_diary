module Api
  module V1
    class BaseController < ActionController::API
      # NOTE: ActionController::APIにはCSRF保護・Cookie・セッションが含まれないため手動でinclude
      include ActionController::RequestForgeryProtection
      include ActionController::Cookies
      include Api::ErrorHandling

      protect_from_forgery with: :exception

      # NOTE: URLに.json拡張子がなくてもJSON形式で応答するため
      before_action :set_default_format
      before_action :authenticate_user!

      private

      def set_default_format
        request.format = :json
      end
    end
  end
end
