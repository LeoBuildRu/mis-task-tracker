require "rails_helper"

RSpec.describe RecurrenceRule, type: :model do
  describe "#occurrences_between" do
    let(:range_start) { Date.new(2026, 6, 1) }
    let(:range_end)   { Date.new(2026, 6, 30) }

    it "daily, interval=1 — все 30 дней" do
      rule = build(:recurrence_rule, frequency: "daily", interval: 1, starts_on: Date.new(2026, 1, 1))
      expect(rule.occurrences_between(range_start, range_end).size).to eq(30)
    end

    it "daily, interval=3 — каждый 3-й день начиная с starts_on" do
      rule = build(:recurrence_rule, frequency: "daily", interval: 3, starts_on: Date.new(2026, 6, 2))
      dates = rule.occurrences_between(range_start, range_end)
      expect(dates.first).to eq(Date.new(2026, 6, 2))
      expect(dates.second).to eq(Date.new(2026, 6, 5))
      expect(dates).to all(satisfy { |d| (d - Date.new(2026, 6, 2)).to_i % 3 == 0 })
    end

    it "monthly — конкретные числа месяца" do
      rule = build(:recurrence_rule, :monthly, starts_on: Date.new(2026, 1, 1),
                                               days_of_month: [1, 15])
      dates = rule.occurrences_between(range_start, range_end)
      expect(dates).to contain_exactly(Date.new(2026, 6, 1), Date.new(2026, 6, 15))
    end

    it "specific_dates — только указанные даты в окне" do
      rule = build(:recurrence_rule, :specific_dates,
                   starts_on: Date.new(2026, 1, 1),
                   specific_dates: [Date.new(2026, 6, 5), Date.new(2026, 7, 5)])
      expect(rule.occurrences_between(range_start, range_end))
        .to contain_exactly(Date.new(2026, 6, 5))
    end

    it "even_days — все чётные числа месяца" do
      rule = build(:recurrence_rule, :even_days, starts_on: Date.new(2026, 1, 1))
      dates = rule.occurrences_between(range_start, range_end)
      expect(dates).to all(satisfy { |d| d.day.even? })
      expect(dates.size).to eq(15)
    end

    it "odd_days — все нечётные числа месяца" do
      rule = build(:recurrence_rule, :odd_days, starts_on: Date.new(2026, 1, 1))
      dates = rule.occurrences_between(range_start, range_end)
      expect(dates).to all(satisfy { |d| d.day.odd? })
      expect(dates.size).to eq(15)
    end

    it "учитывает ends_on" do
      rule = build(:recurrence_rule, frequency: "daily", interval: 1,
                   starts_on: Date.new(2026, 1, 1),
                   ends_on: Date.new(2026, 6, 10))
      dates = rule.occurrences_between(range_start, range_end)
      expect(dates.last).to eq(Date.new(2026, 6, 10))
    end

    it "не разворачивает миллион дат — окно ограничивается клиентом" do
      rule = build(:recurrence_rule, frequency: "daily", interval: 1, starts_on: Date.new(2000, 1, 1))
      expect(rule.occurrences_between(range_start, range_end).size).to eq(30)
    end
  end

  describe "validations" do
    it "требует days_of_month для monthly" do
      rule = build(:recurrence_rule, frequency: "monthly", days_of_month: [])
      expect(rule).not_to be_valid
      expect(rule.errors[:days_of_month]).to be_present
    end

    it "не принимает день > 31" do
      rule = build(:recurrence_rule, frequency: "monthly", days_of_month: [32])
      expect(rule).not_to be_valid
    end

    it "требует specific_dates для specific_dates" do
      rule = build(:recurrence_rule, frequency: "specific_dates", specific_dates: [])
      expect(rule).not_to be_valid
    end

    it "ends_on не может быть раньше starts_on" do
      rule = build(:recurrence_rule, starts_on: Date.new(2026, 6, 1), ends_on: Date.new(2026, 5, 1))
      expect(rule).not_to be_valid
    end
  end
end
