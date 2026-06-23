require "rails_helper"

RSpec.describe "Api::V1::TaskTags", type: :request do
  let(:task) { create(:task) }
  let!(:tag) { create(:tag, name: "ad-hoc") }

  describe "POST /api/v1/tasks/:task_id/tags" do
    it "добавляет существующий тег по tag_id" do
      post "/api/v1/tasks/#{task.id}/tags", params: { tag_id: tag.id }, as: :json
      expect(response).to have_http_status(:created)
      expect(task.reload.tags).to include(tag)
    end

    it "создаёт новый тег по name, если его нет" do
      post "/api/v1/tasks/#{task.id}/tags", params: { name: "по-имени" }, as: :json
      expect(response).to have_http_status(:created)
      expect(task.reload.tags.pluck(:name)).to include("по-имени")
    end

    it "идемпотентно: повторное добавление того же тега не дублирует связь" do
      post "/api/v1/tasks/#{task.id}/tags", params: { tag_id: tag.id }, as: :json
      post "/api/v1/tasks/#{task.id}/tags", params: { tag_id: tag.id }, as: :json
      expect(task.reload.task_tags.count).to eq(1)
    end

    it "400 если нет ни tag_id ни name" do
      post "/api/v1/tasks/#{task.id}/tags", params: {}, as: :json
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "DELETE /api/v1/tasks/:task_id/tags/:id" do
    it "снимает тег с задачи (сам тег не удаляется)" do
      task.tags << tag
      delete "/api/v1/tasks/#{task.id}/tags/#{tag.id}"
      expect(response).to have_http_status(:no_content)
      expect(task.reload.tags).not_to include(tag)
      expect(Tag.where(id: tag.id)).to exist
    end
  end
end
