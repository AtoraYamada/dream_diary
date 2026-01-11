# NOTE: Devise認証失敗時のデフォルト動作（HTMLリダイレクト）をAPI用（JSON応答）にカスタマイズ
class JsonFailureApp < Devise::FailureApp
  def respond
    api_request? ? json_error_response : super
  end

  private

  def json_error_response
    self.status = 401
    self.content_type = :json
    self.response_body = { error: i18n_message }.to_json
  end

  def api_request?
    request.path.start_with?('/api/')
  end
end
