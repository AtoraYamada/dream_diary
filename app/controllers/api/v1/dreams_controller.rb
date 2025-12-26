module Api
  module V1
    class DreamsController < BaseController
      before_action :set_dream, only: [:show, :update, :destroy]

      # GET /api/v1/dreams
      def index
        @dreams = current_user.dreams
                              .includes(:tags)
                              .recent
                              .page(params[:page])
                              .per(params[:per_page] || 12)
      end

      # GET /api/v1/dreams/:id
      def show
        # Jbuilder で自動レンダリング
      end

      # POST /api/v1/dreams
      def create
        ActiveRecord::Base.transaction do
          build_and_save_dream
          attach_tags_to_dream
          render :create, status: :created
        end
      rescue ActiveRecord::RecordInvalid => e
        render_validation_error(e)
      rescue StandardError => e
        render_service_error(e)
      end

      # PUT /api/v1/dreams/:id
      def update
        ActiveRecord::Base.transaction do
          @dream.update!(dream_params)
          update_dream_tags
          render :create, status: :ok # create.json.jbuilder を使い回す
        end
      rescue ActiveRecord::RecordInvalid => e
        render_validation_error(e)
      rescue StandardError => e
        render_service_error(e)
      end

      # DELETE /api/v1/dreams/:id
      def destroy
        @dream.destroy
        head :no_content
      end

      # GET /api/v1/dreams/search
      def search
        @dreams = build_search_base_query
        @dreams = apply_keyword_search(@dreams)
        @dreams = apply_pagination(@dreams)
      end

      # GET /api/v1/dreams/overflow
      def overflow
        dreams = current_user.dreams.order(Arel.sql('RANDOM()')).limit(10)
        result = Dreams::OverflowService.call(dreams)

        if result.success?
          render json: { fragments: result.value }
        else
          render json: { errors: result.errors }, status: :internal_server_error
        end
      end

      private

      def set_dream
        @dream = current_user.dreams.includes(:tags).find(params[:id])
      end

      def dream_params
        params.require(:dream).permit(:title, :content, :emotion_color, :dreamed_at, :lucid_dream_flag)
      end

      def tag_attributes_params
        tag_attrs = params.dig(:dream, :tag_attributes)
        return [] if tag_attrs.blank? || !tag_attrs.is_a?(Array)

        tag_attrs
          .reject { |tag| tag.blank? || tag.is_a?(String) }
          .map { |tag| tag.permit(:name, :yomi, :category) }
      end

      # create action helpers
      def build_and_save_dream
        @dream = current_user.dreams.build(dream_params)
        @dream.save!
      end

      def attach_tags_to_dream
        result = Dreams::AttachTagsService.call(@dream, tag_attributes_params)
        raise StandardError, result.errors.join(', ') if result.failure?
      end

      # update action helpers
      def update_dream_tags
        result = Dreams::UpdateTagsService.call(@dream, tag_attributes_params)
        raise StandardError, result.errors.join(', ') if result.failure?
      end

      # search action helpers
      def build_search_base_query
        if params[:tag_ids].present?
          tag_ids = params[:tag_ids].split(',').map(&:to_i)
          current_user.dreams.tagged_with(tag_ids)
        else
          current_user.dreams.includes(:tags)
        end
      end

      def apply_keyword_search(dreams)
        return dreams if params[:keywords].blank?

        dreams.search_by_keyword(params[:keywords])
      end

      def apply_pagination(dreams)
        dreams.recent.page(params[:page]).per(12)
      end

      # error rendering helpers
      def render_validation_error(exception)
        render json: { errors: exception.record.errors.full_messages },
               status: :unprocessable_content
      end

      def render_service_error(exception)
        render json: { errors: [exception.message] },
               status: :unprocessable_content
      end
    end
  end
end
