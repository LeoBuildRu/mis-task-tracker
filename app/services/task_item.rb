# Lightweight DTO used to represent a single visible task in a date window.
# It can come from a one-off Task or from a (virtual / materialized) occurrence
# of a recurring Task. The controller renders this directly via TaskItemSerializer.
TaskItem = Struct.new(
  :task,             # underlying Task record
  :occurrence,       # TaskOccurrence record or nil (virtual)
  :occurrence_date,  # Date or nil (nil for one-off tasks)
  keyword_init: true
) do
  def recurring?
    task.recurring?
  end

  def materialized?
    occurrence&.persisted?
  end

  def cancelled?
    occurrence&.cancelled? == true
  end

  def status
    occurrence&.status || task.status
  end

  def name
    occurrence&.effective_name || task.name
  end

  def description
    occurrence&.effective_description || task.description
  end

  def scheduled_at
    return occurrence.effective_scheduled_at if occurrence
    return task.scheduled_at unless occurrence_date # one-off task

    # Virtual occurrence: combine its date with the series' time-of-day
    base = task.scheduled_at
    Time.utc(occurrence_date.year, occurrence_date.month, occurrence_date.day,
             base.hour, base.min, base.sec)
  end

  def tags
    task.tags
  end
end
