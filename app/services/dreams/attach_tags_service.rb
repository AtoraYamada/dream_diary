module Dreams
  class AttachTagsService
    def self.call(dream, tag_attributes)
      new(dream, tag_attributes).call
    end

    def initialize(dream, tag_attributes)
      @dream = dream
      @tag_attributes = tag_attributes
      @user = dream.user
    end

    def call
      return ServiceResult.success(@dream) if @tag_attributes.blank?

      attach_tags
      ServiceResult.success(@dream)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(e.record.errors.full_messages)
    rescue StandardError => e
      ServiceResult.failure("栞の綴じ込みに失敗しました: #{e.message}")
    end

    private

    def attach_tags
      @tag_attributes.each do |tag_attr|
        tag = find_or_create_tag(tag_attr)
        @dream.tags << tag unless @dream.tags.include?(tag)
      end
    end

    def find_or_create_tag(tag_attr)
      # name のみでユニーク（現状のDB制約に従う）
      # yomi_index はモデルの before_validation で自動設定される
      @user.tags.find_or_create_by!(name: tag_attr[:name]) do |tag|
        tag.yomi = tag_attr[:yomi]
        tag.category = tag_attr[:category]
      end
    end
  end
end
