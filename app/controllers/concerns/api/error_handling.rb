module Api
  module ErrorHandling
    extend ActiveSupport::Concern

    included do
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_content
    end

    private

    def render_not_found
      render json: {
        error: 'Not Found',
        message: I18n.t('api.errors.not_found')
      }, status: :not_found
    end

    def render_unprocessable_content(exception)
      render json: {
        errors: exception.record.errors.full_messages
      }, status: :unprocessable_content
    end
  end
end
