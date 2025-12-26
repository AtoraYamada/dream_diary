class ServiceResult
  attr_reader :value, :errors

  def initialize(success:, value: nil, errors: [])
    @success = success
    @value = value
    @errors = errors
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  # 便利メソッド
  def self.success(value = nil)
    new(success: true, value: value)
  end

  def self.failure(errors)
    new(success: false, errors: Array(errors))
  end
end
