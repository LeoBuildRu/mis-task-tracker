module Api
  module V1
    class TaskOccurrencesController < ApplicationController
      before_action :set_task
      before_action :ensure_recurring
      before_action :set_occurrence_date
      before_action :ensure_date_in_rule

      # GET /api/v1/tasks/:task_id/occurrences/:date
      def show
        occurrence = @task.task_occurrences.find_by(occurrence_date: @date)
        render json: TaskOccurrenceSerializer.call(@task, @date, occurrence: occurrence)
      end

      # PATCH /api/v1/tasks/:task_id/occurrences/:date
      # body: { occurrence: { status:, scheduled_at:, name:, description: } }
      def update
        occurrence = @task.task_occurrences.find_or_initialize_by(occurrence_date: @date)
        occurrence.assign_attributes(occurrence_params)
        occurrence.cancelled = false if occurrence_params[:status].present?

        if occurrence.save
          render json: TaskOccurrenceSerializer.call(@task, @date, occurrence: occurrence)
        else
          render json: { errors: occurrence.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/tasks/:task_id/occurrences/:date
      # Cancels just this occurrence (the series itself is untouched).
      def destroy
        occurrence = @task.task_occurrences.find_or_initialize_by(occurrence_date: @date)
        occurrence.cancelled = true
        occurrence.status    = "cancelled"
        occurrence.save!
        render json: TaskOccurrenceSerializer.call(@task, @date, occurrence: occurrence)
      end

      private

      def set_task
        @task = Task.find(params[:task_id])
      end

      def ensure_recurring
        return if @task.recurring?

        render json: { error: "Task is not recurring; manage it via /tasks/:id" },
               status: :unprocessable_entity
      end

      def set_occurrence_date
        @date = Date.iso8601(params[:date])
      rescue ArgumentError, Date::Error
        raise ArgumentError, "invalid date: #{params[:date]} (expected YYYY-MM-DD)"
      end

      def ensure_date_in_rule
        return if @task.recurrence_rule.occurrences_between(@date, @date).include?(@date)

        render json: { error: "#{@date} is not a valid occurrence for this task" },
               status: :unprocessable_entity
      end

      def occurrence_params
        params.require(:occurrence).permit(:status, :scheduled_at, :name, :description, :cancelled)
      end
    end
  end
end
