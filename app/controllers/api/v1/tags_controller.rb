module Api
  module V1
    class TagsController < ApplicationController
      before_action :set_tag, only: %i[update destroy]

      # GET /api/v1/tags
      def index
        render json: Tag.order(:name).map { |t| TagSerializer.call(t) }
      end

      # POST /api/v1/tags
      def create
        tag = Tag.new(tag_params.merge(system: false))
        if tag.save
          render json: TagSerializer.call(tag), status: :created
        else
          render json: { errors: tag.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/tags/:id
      def update
        if @tag.update(tag_params)
          render json: TagSerializer.call(@tag)
        else
          # System tag protection produces a base error → 403
          status = @tag.system? ? :forbidden : :unprocessable_entity
          render json: { errors: @tag.errors.full_messages }, status: status
        end
      end

      # DELETE /api/v1/tags/:id
      def destroy
        if @tag.system?
          return render json: { errors: ["Системный тег нельзя удалять"] }, status: :forbidden
        end

        if @tag.destroy
          head :no_content
        else
          render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_tag
        @tag = Tag.find(params[:id])
      end

      def tag_params
        params.require(:tag).permit(:name)
      end
    end
  end
end
