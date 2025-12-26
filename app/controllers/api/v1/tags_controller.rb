module Api
  module V1
    class TagsController < BaseController
      before_action :set_tag, only: [:destroy]

      # GET /api/v1/tags
      def index
        @tags = current_user.tags

        @tags = @tags.by_category(params[:category]) if params[:category].present?
        @tags = @tags.by_yomi_index(params[:yomi_index]) if params[:yomi_index].present?
      end

      # GET /api/v1/tags/suggest
      def suggest
        @tags = current_user.tags.search_by_name_or_yomi(params[:query])
        @tags = @tags.by_category(params[:category]) if params[:category].present?
        @tags = @tags.limit(10)
      end

      # DELETE /api/v1/tags/:id
      def destroy
        @tag.destroy
        head :no_content
      end

      private

      def set_tag
        @tag = current_user.tags.find(params[:id])
      end
    end
  end
end
