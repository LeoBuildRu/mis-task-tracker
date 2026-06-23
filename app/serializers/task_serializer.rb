# Serializes the full series record. Used by show / create / update on a Task.
class TaskSerializer
  def self.call(task)
    {
      id: task.id,
      name: task.name,
      description: task.description,
      scheduled_at: task.scheduled_at&.iso8601,
      status: task.status,
      recurring: task.recurring?,
      recurrence_rule: RecurrenceRuleSerializer.call(task.recurrence_rule),
      tags: task.tags.map { |t| TagSerializer.call(t) },
      created_at: task.created_at.iso8601,
      updated_at: task.updated_at.iso8601
    }
  end
end
