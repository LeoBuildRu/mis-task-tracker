require "rails_helper"

RSpec.describe TaskOccurrence, type: :model do
  let(:task) do
    create(:task, :recurring,
           scheduled_at: Time.utc(2026, 6, 1, 9, 30),
           recurrence_rule: build(:recurrence_rule, frequency: "daily", interval: 1,
                                                    starts_on: Date.new(2026, 6, 1)))
  end

  it "уникальна по (task_id, occurrence_date)" do
    create(:task_occurrence, task: task, occurrence_date: Date.new(2026, 6, 2))
    duplicate = build(:task_occurrence, task: task, occurrence_date: Date.new(2026, 6, 2))
    expect(duplicate).not_to be_valid
  end

  it "требует, чтобы задача была периодической" do
    one_off = create(:task)
    occurrence = build(:task_occurrence, task: one_off, occurrence_date: Date.current)
    expect(occurrence).not_to be_valid
    expect(occurrence.errors[:task]).to be_present
  end

  describe "#effective_scheduled_at" do
    it "по умолчанию = дата occurrence + время серии" do
      occ = task.task_occurrences.build(occurrence_date: Date.new(2026, 6, 5))
      expect(occ.effective_scheduled_at).to eq(Time.utc(2026, 6, 5, 9, 30))
    end

    it "переопределяется явным scheduled_at" do
      occ = task.task_occurrences.build(occurrence_date: Date.new(2026, 6, 5),
                                        scheduled_at: Time.utc(2026, 6, 5, 14, 0))
      expect(occ.effective_scheduled_at).to eq(Time.utc(2026, 6, 5, 14, 0))
    end
  end
end
