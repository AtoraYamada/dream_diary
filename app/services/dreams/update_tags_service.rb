module Dreams
  class UpdateTagsService
    def self.call(dream, tag_attributes)
      new(dream, tag_attributes).call
    end

    def initialize(dream, tag_attributes)
      @dream = dream
      @tag_attributes = tag_attributes
    end

    def call
      @dream.tags.clear
      AttachTagsService.call(@dream, @tag_attributes)
    end
  end
end
