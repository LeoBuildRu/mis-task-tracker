# Serializes a single occurrence (materialized or virtual) of a recurring task.
class TaskOccurrenceSerializer
  def self.call(task, occurrence_date, occurrence: nil)
    item = TaskItem.new(task: task, occurrence: occurrence, occurrence_date: occurrence_date)
    {
      task_id: task.id,
      occurrence_id: occurrence&.id,
      occurrence_date: occurrence_date.iso8601,
      name: item.name,
      description: item.description,
      scheduled_at: item.scheduled_at&.iso8601,
      status: item.status,
      cancelled: occurrence&.cancelled? == true,
      override: occurrence&.override? == true,
      tags: task.tags.map { |t| TagSerializer.call(t) }
    }
  end
end
