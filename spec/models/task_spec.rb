require "rails_helper"

RSpec.describe Task, type: :model do
  it "валидна с минимальным набором полей" do
    expect(build(:task)).to be_valid
  end

  it "требует name и scheduled_at" do
    task = Task.new
    expect(task).not_to be_valid
    expect(task.errors[:name]).to be_present
    expect(task.errors[:scheduled_at]).to be_present
  end

  it "recurring? = true когда есть recurrence_rule" do
    expect(build(:task, :recurring)).to be_recurring
    expect(build(:task)).not_to be_recurring
  end

  it "удаление задачи удаляет её recurrence_rule" do
    task = create(:task, :recurring)
    rule_id = task.recurrence_rule_id
    task.destroy
    expect(RecurrenceRule.where(id: rule_id)).not_to exist
  end
end
