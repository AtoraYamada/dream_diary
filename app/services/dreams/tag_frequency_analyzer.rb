# frozen_string_literal: true

module Dreams
  # 直近の夢から多用タグを分析するサービス
  class TagFrequencyAnalyzer
    # 定数定義
    RECENT_DREAMS_LIMIT = 10  # 分析対象とする直近の夢の件数
    FREQUENCY_THRESHOLD = 2   # 多用タグと判定する使用回数の閾値

    # 直近10回分の夢から2回以上使われたタグIDを返す
    #
    # @param user [User] 分析対象のユーザー
    # @return [Array<Integer>] 2回以上使われたタグのID配列
    def self.call(user)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      # 直近の夢IDを取得
      dream_ids = @user.dreams.order(dreamed_at: :desc).limit(RECENT_DREAMS_LIMIT).pluck(:id)
      return [] if dream_ids.empty?

      # SQLレベルで集計（N+1クエリを回避）
      DreamTag
        .where(dream_id: dream_ids)
        .group(:tag_id)
        .having('COUNT(*) >= ?', FREQUENCY_THRESHOLD)
        .pluck(:tag_id)
    end
  end
end
