require "rails_helper"

RSpec.describe "Api::V1::Tags", type: :request do
  before { Tag.ensure_system_tags! }

  describe "GET /api/v1/tags" do
    it "возвращает все теги" do
      create(:tag, name: "custom")
      get "/api/v1/tags"
      expect(response).to have_http_status(:ok)
      names = response.parsed_body.map { |t| t["name"] }
      expect(names).to include(*Tag::SYSTEM_TAG_NAMES, "custom")
    end
  end

  describe "POST /api/v1/tags" do
    it "создаёт обычный (не системный) тег" do
      post "/api/v1/tags", params: { tag: { name: "Новый" } }, as: :json
      expect(response).to have_http_status(:created)
      expect(response.parsed_body["system"]).to be(false)
    end

    it "422 при дубликате" do
      create(:tag, name: "Дубль")
      post "/api/v1/tags", params: { tag: { name: "дубль" } }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/tags/:id" do
    it "редактирует обычный тег" do
      tag = create(:tag, name: "old")
      patch "/api/v1/tags/#{tag.id}", params: { tag: { name: "new" } }, as: :json
      expect(response).to have_http_status(:ok)
      expect(tag.reload.name).to eq("new")
    end

    it "запрещает редактирование системного тега → 403" do
      system_tag = Tag.system.first
      patch "/api/v1/tags/#{system_tag.id}", params: { tag: { name: "x" } }, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/tags/:id" do
    it "удаляет обычный тег" do
      tag = create(:tag, name: "to-delete")
      delete "/api/v1/tags/#{tag.id}"
      expect(response).to have_http_status(:no_content)
    end

    it "запрещает удаление системного тега → 403" do
      system_tag = Tag.system.first
      delete "/api/v1/tags/#{system_tag.id}"
      expect(response).to have_http_status(:forbidden)
      expect(Tag.where(id: system_tag.id)).to exist
    end
  end
end
