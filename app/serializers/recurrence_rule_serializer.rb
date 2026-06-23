class RecurrenceRuleSerializer
  def self.call(rule)
    return nil unless rule

    {
      id: rule.id,
      frequency: rule.frequency,
      interval: rule.interval,
      days_of_month: rule.days_of_month,
      specific_dates: rule.specific_dates,
      starts_on: rule.starts_on,
      ends_on: rule.ends_on
    }
  end
end
