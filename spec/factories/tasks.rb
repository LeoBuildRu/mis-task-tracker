FactoryBot.define do
  factory :task do
    sequence(:name) { |n| "Task ##{n}" }
    description     { "Test description" }
    scheduled_at    { Time.utc(2026, 6, 23, 10, 0, 0) }
    status          { "pending" }

    trait :recurring do
      association :recurrence_rule
    end
  end

  factory :task_occurrence do
    association :task, :recurring
    occurrence_date { task.scheduled_at.to_date }
    status          { "pending" }
    cancelled       { false }
  end
end
