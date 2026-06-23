require "rails_helper"

RSpec.describe Tag, type: :model do
  describe "validations" do
    it "требует name" do
      tag = Tag.new(name: nil)
      expect(tag).not_to be_valid
      expect(tag.errors[:name]).to be_present
    end

    it "does not allow duplicate names (case-insensitive)" do
      create(:tag, name: "Звонок-доп")
      duplicate = build(:tag, name: "звонок-доп")
      expect(duplicate).not_to be_valid
    end
  end

  describe "система обязательных тегов" do
    it "создаёт три системных тега через ensure_system_tags!" do
      Tag.ensure_system_tags!
      expect(Tag.system.pluck(:name)).to match_array(Tag::SYSTEM_TAG_NAMES)
    end

    it "запрещает изменение имени системного тега" do
      Tag.ensure_system_tags!
      tag = Tag.system.first
      tag.name = "новое-имя"
      expect(tag.save).to be(false)
      expect(tag.errors[:base]).to include("Системный тег нельзя изменять")
    end

    it "запрещает удаление системного тега" do
      Tag.ensure_system_tags!
      tag = Tag.system.first
      expect(tag.destroy).to be(false)
      expect(Tag.where(id: tag.id)).to exist
    end

    it "позволяет редактировать обычный тег" do
      tag = create(:tag, name: "тренировка")
      tag.update!(name: "тренировки")
      expect(tag.reload.name).to eq("тренировки")
    end

    it "позволяет удалять обычный тег без задач" do
      tag = create(:tag, name: "удаляемый")
      expect(tag.destroy).to be_truthy
    end
  end
end
