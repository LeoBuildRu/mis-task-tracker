class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound,         with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid,          with: :render_unprocessable
  rescue_from ActionController::ParameterMissing,   with: :render_bad_request
  rescue_from ArgumentError,                        with: :render_bad_request
  rescue_from Date::Error,                          with: :render_bad_request

  private

  def render_not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end

  def render_unprocessable(exception)
    render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
  end

  def render_bad_request(exception)
    render json: { error: exception.message }, status: :bad_request
  end
end
