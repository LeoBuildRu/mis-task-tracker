module Api
  module V1
    class TasksController < ApplicationController
      before_action :set_task, only: %i[show update destroy]

      # GET /api/v1/tasks?from=YYYY-MM-DD&to=YYYY-MM-DD&status=...&tag_ids[]=...
      def index
        from = parse_date(params[:from]) || Date.current
        to   = parse_date(params[:to])   || (from + 30.days)

        result = TasksQuery.call(
          from: from,
          to: to,
          status: params[:status],
          tag_ids: params[:tag_ids]
        )

        render json: {
          from: result.from.iso8601,
          to: result.to.iso8601,
          items: result.items.map { |i| TaskItemSerializer.call(i) }
        }
      end

      # GET /api/v1/tasks/:id
      def show
        render json: TaskSerializer.call(@task)
      end

      # POST /api/v1/tasks
      def create
        task = Task.new(task_params)
        task.tag_ids = tag_ids_param if params[:task].key?(:tag_ids)

        if task.save
          render json: TaskSerializer.call(task), status: :created
        else
          render json: { errors: task.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/tasks/:id
      def update
        @task.assign_attributes(task_params)
        @task.tag_ids = tag_ids_param if params[:task].key?(:tag_ids)

        if @task.save
          render json: TaskSerializer.call(@task)
        else
          render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/tasks/:id
      def destroy
        @task.destroy
        head :no_content
      end

      private

      def set_task
        @task = Task.find(params[:id])
      end

      def task_params
        params.require(:task).permit(
          :name, :description, :scheduled_at, :status,
          recurrence_rule_attributes: [
            :id, :frequency, :interval, :starts_on, :ends_on, :_destroy,
            { days_of_month: [], specific_dates: [] }
          ]
        )
      end

      def tag_ids_param
        Array(params.require(:task)[:tag_ids]).map(&:to_i).reject(&:zero?)
      end

      def parse_date(value)
        return nil if value.blank?

        Date.iso8601(value.to_s)
      rescue ArgumentError, Date::Error
        raise ArgumentError, "invalid date: #{value} (expected YYYY-MM-DD)"
      end
    end
  end
end
