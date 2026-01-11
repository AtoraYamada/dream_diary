class Api::V1::SessionsController < Devise::SessionsController
  # NOTE: Devise::SessionsControllerはBaseControllerを継承しないため手動でinclude
  include ActionController::RequestForgeryProtection
  include ActionController::Cookies
  protect_from_forgery with: :exception

  rescue_from ActionController::InvalidAuthenticityToken do
    render json: { error: I18n.t('api.errors.csrf_verification_failed') }, status: :forbidden
  end

  respond_to :json

  # NOTE: デフォルトはHTMLリダイレクト。APIではログアウト済みでもエラーにせず状態のみ保存
  def verify_signed_out_user
    @user_was_signed_in = signed_in?(resource_name)
  end

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: {
        message: '記憶の鍵が噛み合い、閉ざされていた書斎の扉が開きました。',
        user: {
          id: resource.id,
          email: resource.email,
          username: resource.username
        }
      }, status: :ok
    else
      render json: {
        error: I18n.t('devise.failure.invalid')
      }, status: :unauthorized
    end
  end

  def respond_to_on_destroy
    if @user_was_signed_in
      render json: { message: '記録の筆を置きました。夢の続きは、また次の眠りの果てに。' }, status: :ok
    else
      render json: { error: '既に目覚めています。ここには貴方の影すら残っていません' }, status: :unauthorized
    end
  end
end
