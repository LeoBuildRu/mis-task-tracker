# Returns the list of TaskItems for a given date window. Combines:
#   * one-off tasks whose scheduled_at falls inside the window
#   * recurring tasks expanded into virtual occurrences inside the window,
#     overlaid with any persisted TaskOccurrence rows (overrides).
#
# Filters: status (one of Task::STATUSES), tag_ids (Array<Integer>).
#
# The window is capped (MAX_WINDOW_DAYS) so a careless `from / to`
# cannot expand to millions of dates.
class TasksQuery < ApplicationService
  MAX_WINDOW_DAYS = 366

  Result = Struct.new(:items, :from, :to, keyword_init: true)

  def initialize(from:, to:, status: nil, tag_ids: [])
    @from    = from.to_date
    @to      = to.to_date
    @status  = status.presence
    @tag_ids = Array(tag_ids).map(&:to_i).reject(&:zero?)
  end

  def call
    raise ArgumentError, "to must be >= from" if @to < @from

    if (@to - @from).to_i > MAX_WINDOW_DAYS
      raise ArgumentError, "window must be <= #{MAX_WINDOW_DAYS} days"
    end

    items = one_off_items + recurring_items
    items = items.select { |i| i.status == @status } if @status
    items.sort_by! { |i| [i.scheduled_at, i.task.id] }
    Result.new(items: items, from: @from, to: @to)
  end

  private

  def one_off_items
    scope = base_scope.one_off
                      .where(scheduled_at: window_start..window_end)
                      .includes(:tags)
    scope.map { |t| TaskItem.new(task: t, occurrence: nil, occurrence_date: nil) }
  end

  def recurring_items
    recurring = base_scope.recurring
                          .includes(:recurrence_rule, :tags,
                                    :task_occurrences)

    items = []
    recurring.find_each do |task|
      next unless task.recurrence_rule

      overrides = task.task_occurrences
                      .where(occurrence_date: @from..@to)
                      .index_by(&:occurrence_date)

      task.recurrence_rule.occurrences_between(@from, @to).each do |date|
        occ = overrides[date]
        next if occ&.cancelled?

        items << TaskItem.new(task: task, occurrence: occ, occurrence_date: date)
      end
    end
    items
  end

  def base_scope
    scope = Task.all
    if @tag_ids.any?
      scope = scope.joins(:task_tags)
                   .where(task_tags: { tag_id: @tag_ids })
                   .distinct
    end
    scope
  end

  def window_start
    @from.beginning_of_day
  end

  def window_end
    @to.end_of_day
  end
end
