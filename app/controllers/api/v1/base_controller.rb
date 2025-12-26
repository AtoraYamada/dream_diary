module Api
  module V1
    class BaseController < ActionController::API
      include Api::ErrorHandling

      before_action :set_default_format
      before_action :authenticate_user!

      private

      def set_default_format
        request.format = :json
      end
    end
  end
end
