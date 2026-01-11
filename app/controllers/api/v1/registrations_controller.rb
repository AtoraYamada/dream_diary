class Api::V1::RegistrationsController < Devise::RegistrationsController
  # NOTE: Devise::RegistrationsControllerはBaseControllerを継承しないため手動でinclude
  include ActionController::RequestForgeryProtection
  include ActionController::Cookies
  protect_from_forgery with: :exception

  rescue_from ActionController::InvalidAuthenticityToken do
    render json: { error: I18n.t('api.errors.csrf_verification_failed') }, status: :forbidden
  end

  respond_to :json
  before_action :configure_sign_up_params, only: [:create]

  protected

  # NOTE: authentication_keys=[:login]変更により、Deviseデフォルトが[:login, :password, :password_confirmation]に変更
  #       sign_upでは:loginでなく:emailと:usernameを個別に受け取るため、両方を追加で許可
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :email])
  end

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: {
        message: '入館の手続きが完了しました。貴方の筆録者としての歩みが始まります。',
        user: {
          id: resource.id,
          email: resource.email,
          username: resource.username
        }
      }, status: :created
    else
      render json: {
        errors: resource.errors.full_messages
      }, status: :unprocessable_content
    end
  end
end
