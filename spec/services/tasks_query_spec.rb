require "rails_helper"

RSpec.describe TasksQuery do
  describe "одноразовые задачи" do
    it "возвращает только те, что попадают в окно" do
      in_window  = create(:task, scheduled_at: Time.utc(2026, 6, 10, 9))
      _outside   = create(:task, scheduled_at: Time.utc(2026, 7, 1, 9))

      result = described_class.call(from: Date.new(2026, 6, 1), to: Date.new(2026, 6, 30))
      expect(result.items.map { |i| i.task.id }).to eq([in_window.id])
    end
  end

  describe "периодические задачи" do
    let(:task) do
      create(:task,
             scheduled_at: Time.utc(2026, 6, 1, 9, 0),
             recurrence_rule: build(:recurrence_rule,
                                    frequency: "daily", interval: 1,
                                    starts_on: Date.new(2026, 6, 1)))
    end

    it "разворачивает в виртуальные оккуренсы" do
      result = described_class.call(from: Date.new(2026, 6, 1), to: Date.new(2026, 6, 7))
      expect(result.items.size).to eq(7)
      expect(result.items.map { |i| i.occurrence_date }).to eq((Date.new(2026, 6, 1)..Date.new(2026, 6, 7)).to_a)
    end

    it "оккуренсы по умолчанию имеют статус pending и не материализуются в БД" do
      described_class.call(from: Date.new(2026, 6, 1), to: Date.new(2026, 6, 7))
      expect(TaskOccurrence.count).to eq(0)
    end

    it "виртуальный оккуренс имеет scheduled_at на свою дату, не на дату серии" do
      result = described_class.call(from: Date.new(2026, 6, 1), to: Date.new(2026, 6, 7))
      day3 = result.items.find { |i| i.occurrence_date == Date.new(2026, 6, 3) }
      expect(day3.scheduled_at).to eq(Time.utc(2026, 6, 3, 9, 0))
    end

    it "материализованный override переопределяет статус и время" do
      task.task_occurrences.create!(
        occurrence_date: Date.new(2026, 6, 3),
        status: "completed",
        scheduled_at: Time.utc(2026, 6, 3, 14, 0)
      )

      result = described_class.call(from: Date.new(2026, 6, 1), to: Date.new(2026, 6, 7))
      day3 = result.items.find { |i| i.occurrence_date == Date.new(2026, 6, 3) }
      expect(day3.status).to eq("completed")
      expect(day3.scheduled_at).to eq(Time.utc(2026, 6, 3, 14, 0))
    end

    it "отменённый (cancelled) оккуренс выпадает из списка" do
      task.task_occurrences.create!(occurrence_date: Date.new(2026, 6, 3), cancelled: true, status: "cancelled")
      result = described_class.call(from: Date.new(2026, 6, 1), to: Date.new(2026, 6, 7))
      expect(result.items.map(&:occurrence_date)).not_to include(Date.new(2026, 6, 3))
      expect(result.items.size).to eq(6)
    end
  end

  describe "фильтры" do
    it "фильтрует по статусу" do
      create(:task, status: "pending",   scheduled_at: Time.utc(2026, 6, 10, 9))
      create(:task, status: "completed", scheduled_at: Time.utc(2026, 6, 11, 9))

      result = described_class.call(from: Date.new(2026, 6, 1), to: Date.new(2026, 6, 30), status: "pending")
      expect(result.items.size).to eq(1)
      expect(result.items.first.status).to eq("pending")
    end

    it "фильтрует по tag_ids" do
      tag_a = create(:tag, name: "alpha")
      tag_b = create(:tag, name: "beta")
      task_a = create(:task, scheduled_at: Time.utc(2026, 6, 10, 9), tags: [tag_a])
      _task_b = create(:task, scheduled_at: Time.utc(2026, 6, 11, 9), tags: [tag_b])

      result = described_class.call(from: Date.new(2026, 6, 1), to: Date.new(2026, 6, 30),
                                    tag_ids: [tag_a.id])
      expect(result.items.map { |i| i.task.id }).to eq([task_a.id])
    end
  end

  describe "защита от слишком большого окна" do
    it "падает с ArgumentError если окно > MAX_WINDOW_DAYS" do
      expect {
        described_class.call(from: Date.new(2026, 1, 1), to: Date.new(2028, 1, 1))
      }.to raise_error(ArgumentError, /window/)
    end
  end
end
