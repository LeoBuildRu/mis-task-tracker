# Serializes a TaskItem (used in the list endpoint). One-off tasks and
# recurring occurrences share this representation; the latter carry an
# `occurrence_date` and may signal `override: true` if a per-date row
# overrides the series.
class TaskItemSerializer
  def self.call(item)
    {
      task_id: item.task.id,
      occurrence_id: item.occurrence&.id,
      occurrence_date: item.occurrence_date&.iso8601,
      name: item.name,
      description: item.description,
      scheduled_at: item.scheduled_at&.iso8601,
      status: item.status,
      recurring: item.recurring?,
      override: item.materialized? ? item.occurrence.override? : false,
      tags: item.tags.map { |t| TagSerializer.call(t) }
    }
  end
end
