class TaskOccurrence < ApplicationRecord
  belongs_to :task

  enum :status, Task::STATUSES.index_with(&:itself), validate: true

  validates :occurrence_date, presence: true,
                              uniqueness: { scope: :task_id }
  validate :task_must_be_recurring

  def effective_scheduled_at
    return scheduled_at if scheduled_at.present?

    base = task.scheduled_at
    Time.utc(occurrence_date.year, occurrence_date.month, occurrence_date.day,
             base.hour, base.min, base.sec)
  end

  def effective_name
    name.presence || task.name
  end

  def effective_description
    description.presence || task.description
  end

  def override?
    [scheduled_at, name, description].any?(&:present?) || cancelled? || status != "pending"
  end

  private

  def task_must_be_recurring
    return if task&.recurring?

    errors.add(:task, "должна быть периодической")
  end
end
