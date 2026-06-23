class RecurrenceRule < ApplicationRecord
  FREQUENCIES = %w[daily monthly specific_dates even_days odd_days].freeze

  has_one :task, dependent: :nullify

  enum :frequency, FREQUENCIES.index_with(&:itself), validate: true

  validates :starts_on, presence: true
  validate :validate_frequency_params
  validate :validate_ends_on_after_starts_on

  # Returns an array of Date objects for every occurrence between
  # range_start and range_end (inclusive), clamped to the rule's own
  # starts_on / ends_on window.
  def occurrences_between(range_start, range_end)
    range_start = range_start.to_date
    range_end   = range_end.to_date

    effective_start = [starts_on, range_start].max
    effective_end   = ends_on ? [ends_on, range_end].min : range_end
    return [] if effective_start > effective_end

    case frequency
    when "daily"          then daily_dates(effective_start, effective_end)
    when "monthly"        then monthly_dates(effective_start, effective_end)
    when "specific_dates" then specific_dates_in_range(effective_start, effective_end)
    when "even_days"      then (effective_start..effective_end).select { |d| d.day.even? }
    when "odd_days"       then (effective_start..effective_end).select { |d| d.day.odd? }
    else []
    end
  end

  private

  def daily_dates(range_start, range_end)
    step = interval.to_i
    return [] if step < 1

    diff = (range_start - starts_on).to_i
    offset = diff.positive? && (diff % step).positive? ? step - (diff % step) : 0
    first = range_start + offset
    return [] if first > range_end

    dates = []
    date = first
    while date <= range_end
      dates << date
      date += step
    end
    dates
  end

  def monthly_dates(range_start, range_end)
    return [] if days_of_month.blank?

    days = days_of_month.uniq
    (range_start..range_end).select { |d| days.include?(d.day) }
  end

  def specific_dates_in_range(range_start, range_end)
    Array(specific_dates).compact.select { |d| d >= range_start && d <= range_end }.sort
  end

  def validate_frequency_params
    case frequency
    when "daily"
      errors.add(:interval, "должен быть положительным") if interval.blank? || interval < 1
    when "monthly"
      if days_of_month.blank?
        errors.add(:days_of_month, "не может быть пустым для monthly")
      elsif days_of_month.any? { |d| d.nil? || d < 1 || d > 31 }
        errors.add(:days_of_month, "должны быть числами от 1 до 31")
      end
    when "specific_dates"
      if Array(specific_dates).compact.empty?
        errors.add(:specific_dates, "не может быть пустым для specific_dates")
      end
    end
  end

  def validate_ends_on_after_starts_on
    return if ends_on.blank? || starts_on.blank?
    return if ends_on >= starts_on

    errors.add(:ends_on, "должен быть не раньше starts_on")
  end
end
