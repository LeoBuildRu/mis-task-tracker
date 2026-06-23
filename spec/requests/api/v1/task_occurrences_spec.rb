require "rails_helper"

RSpec.describe "Api::V1::TaskOccurrences", type: :request do
  let(:task) do
    create(:task,
           scheduled_at: Time.utc(2026, 6, 1, 10, 0),
           recurrence_rule: build(:recurrence_rule, frequency: "daily", interval: 1,
                                                    starts_on: Date.new(2026, 6, 1)))
  end

  describe "GET /api/v1/tasks/:id/occurrences/:date" do
    it "возвращает виртуальный оккуренс (без записи в БД)" do
      get "/api/v1/tasks/#{task.id}/occurrences/2026-06-05"
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["occurrence_date"]).to eq("2026-06-05")
      expect(body["status"]).to eq("pending")
      expect(body["occurrence_id"]).to be_nil
      expect(TaskOccurrence.count).to eq(0)
    end

    it "422 если дата не совпадает с правилом" do
      task_specific = create(:task,
                             scheduled_at: Time.utc(2026, 6, 1, 10),
                             recurrence_rule: build(:recurrence_rule, :specific_dates,
                                                    specific_dates: [Date.new(2026, 6, 1)]))
      get "/api/v1/tasks/#{task_specific.id}/occurrences/2026-06-15"
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "422 если задача не периодическая" do
      one_off = create(:task)
      get "/api/v1/tasks/#{one_off.id}/occurrences/2026-06-01"
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/tasks/:id/occurrences/:date" do
    it "материализует override и помечает выполненным только этот день" do
      patch "/api/v1/tasks/#{task.id}/occurrences/2026-06-03",
            params: { occurrence: { status: "completed" } }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("completed")
      expect(response.parsed_body["override"]).to be(true)

      # Другие дни не затронуты
      get "/api/v1/tasks/#{task.id}/occurrences/2026-06-04"
      expect(response.parsed_body["status"]).to eq("pending")
    end

    it "позволяет перенести время конкретного экземпляра" do
      patch "/api/v1/tasks/#{task.id}/occurrences/2026-06-03",
            params: { occurrence: { scheduled_at: "2026-06-03T14:00:00Z" } }, as: :json
      expect(response.parsed_body["scheduled_at"]).to eq("2026-06-03T14:00:00Z")
    end
  end

  describe "DELETE /api/v1/tasks/:id/occurrences/:date" do
    it "отменяет конкретный экземпляр, серия продолжается" do
      delete "/api/v1/tasks/#{task.id}/occurrences/2026-06-03"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["cancelled"]).to be(true)

      get "/api/v1/tasks", params: { from: "2026-06-01", to: "2026-06-07" }
      dates = response.parsed_body["items"].map { |i| i["occurrence_date"] }
      expect(dates).not_to include("2026-06-03")
      expect(dates.compact.size).to eq(6)
    end
  end
end
