module Dreams
  class OverflowService
    FALLBACK_FRAGMENTS = [
      '遠くで鐘が鳴っている',
      '鍵は開いたままだ',
      '古びた本棚に埃が積もっている',
      '森の奥から誰かが呼んでいる',
      '月が二つ見える',
      '時計の針が逆回りしている',
      '窓の外に誰かの影が見える'
    ].freeze

    def self.call(dreams)
      new(dreams).call
    end

    def initialize(dreams)
      @dreams = dreams
    end

    def call
      fragments = extract_fragments
      fragments = add_fallback_if_needed(fragments)
      selected = fragments.shuffle.take(rand(5..8))

      ServiceResult.success(selected)
    rescue StandardError => e
      ServiceResult.failure("夢の氾濫に失敗しました: #{e.message}")
    end

    private

    def extract_fragments
      fragments = []

      @dreams.each do |dream|
        sentences = dream.content.split(/[。！？]/)
        fragments.concat(sentences.compact_blank)
      end

      fragments
    end

    def add_fallback_if_needed(fragments)
      return fragments if fragments.size >= 5

      fragments + FALLBACK_FRAGMENTS
    end
  end
end
