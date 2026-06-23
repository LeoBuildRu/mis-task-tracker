module Api
  module V1
    class TaskTagsController < ApplicationController
      before_action :set_task

      # POST /api/v1/tasks/:task_id/tags
      # body: { tag_id: 123 }  OR  { name: "новый-тег" }
      def create
        tag = find_or_create_tag
        return if performed?

        @task.tags << tag unless @task.tag_ids.include?(tag.id)
        render json: TaskSerializer.call(@task.reload), status: :created
      end

      # DELETE /api/v1/tasks/:task_id/tags/:id
      def destroy
        tag = Tag.find(params[:id])
        @task.tags.destroy(tag)
        head :no_content
      end

      private

      def set_task
        @task = Task.find(params[:task_id])
      end

      def find_or_create_tag
        if params[:tag_id].present?
          Tag.find(params[:tag_id])
        elsif params[:name].present?
          name = params[:name].to_s.strip
          Tag.where("LOWER(name) = ?", name.downcase).first ||
            Tag.create!(name: name, system: false)
        else
          render json: { error: "Provide tag_id or name" }, status: :bad_request
          nil
        end
      end
    end
  end
end
