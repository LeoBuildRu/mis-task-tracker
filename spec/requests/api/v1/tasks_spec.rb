require "rails_helper"

RSpec.describe "Api::V1::Tasks", type: :request do
  describe "POST /api/v1/tasks" do
    it "создаёт одноразовую задачу" do
      tag = create(:tag, name: "обход")

      post "/api/v1/tasks", params: {
        task: {
          name: "Обход 5-го корпуса",
          description: "Утром",
          scheduled_at: "2026-06-23T10:00:00Z",
          status: "pending",
          tag_ids: [tag.id]
        }
      }, as: :json

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["name"]).to eq("Обход 5-го корпуса")
      expect(body["tags"].first["id"]).to eq(tag.id)
      expect(body["recurring"]).to be(false)
    end

    it "создаёт периодическую задачу с правилом" do
      post "/api/v1/tasks", params: {
        task: {
          name: "Ежедневный обзвон",
          scheduled_at: "2026-06-01T10:00:00Z",
          recurrence_rule_attributes: {
            frequency: "daily",
            interval: 1,
            starts_on: "2026-06-01"
          }
        }
      }, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["recurring"]).to be(true)
      expect(response.parsed_body["recurrence_rule"]["frequency"]).to eq("daily")
    end

    it "возвращает 422 без name" do
      post "/api/v1/tasks", params: { task: { scheduled_at: "2026-06-01T10:00:00Z" } }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to be_present
    end
  end

  describe "GET /api/v1/tasks" do
    it "возвращает одноразовые и развёрнутые периодические задачи" do
      create(:task, name: "Once", scheduled_at: Time.utc(2026, 6, 10, 9))
      create(:task, name: "Daily", scheduled_at: Time.utc(2026, 6, 1, 9),
                    recurrence_rule: build(:recurrence_rule, frequency: "daily", interval: 1,
                                                              starts_on: Date.new(2026, 6, 1)))

      get "/api/v1/tasks", params: { from: "2026-06-01", to: "2026-06-07" }
      expect(response).to have_http_status(:ok)
      items = response.parsed_body["items"]
      # 7 daily + 0 one-off (вне окна 10/06)... одноразовая 10 июня не входит
      daily_items = items.select { |i| i["name"] == "Daily" }
      expect(daily_items.size).to eq(7)
    end

    it "фильтрует по статусу" do
      create(:task, status: "completed", scheduled_at: Time.utc(2026, 6, 10, 9))
      create(:task, status: "pending",   scheduled_at: Time.utc(2026, 6, 11, 9))
      get "/api/v1/tasks", params: { from: "2026-06-01", to: "2026-06-30", status: "completed" }
      expect(response.parsed_body["items"].size).to eq(1)
    end

    it "400 на невалидную дату" do
      get "/api/v1/tasks", params: { from: "not-a-date" }
      expect(response).to have_http_status(:bad_request)
    end

    it "у виртуальных оккуренсов override = false (не null)" do
      create(:task, scheduled_at: Time.utc(2026, 6, 1, 9),
                    recurrence_rule: build(:recurrence_rule, frequency: "daily", interval: 1,
                                                             starts_on: Date.new(2026, 6, 1)))
      get "/api/v1/tasks", params: { from: "2026-06-01", to: "2026-06-03" }
      items = response.parsed_body["items"]
      expect(items).to all(include("override" => false))
    end
  end

  describe "PATCH /api/v1/tasks/:id" do
    it "обновляет поля" do
      task = create(:task)
      patch "/api/v1/tasks/#{task.id}", params: { task: { status: "in_progress" } }, as: :json
      expect(response).to have_http_status(:ok)
      expect(task.reload.status).to eq("in_progress")
    end
  end

  describe "DELETE /api/v1/tasks/:id" do
    it "удаляет задачу" do
      task = create(:task)
      delete "/api/v1/tasks/#{task.id}"
      expect(response).to have_http_status(:no_content)
      expect(Task.where(id: task.id)).not_to exist
    end
  end
end
