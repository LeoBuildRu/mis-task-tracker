FactoryBot.define do
  factory :recurrence_rule do
    frequency      { "daily" }
    interval       { 1 }
    starts_on      { Date.new(2026, 1, 1) }
    ends_on        { nil }
    days_of_month  { [] }
    specific_dates { [] }

    trait :monthly do
      frequency     { "monthly" }
      days_of_month { [1, 15] }
    end

    trait :specific_dates do
      frequency      { "specific_dates" }
      specific_dates { [Date.new(2026, 6, 1), Date.new(2026, 6, 15)] }
    end

    trait :even_days do
      frequency { "even_days" }
    end

    trait :odd_days do
      frequency { "odd_days" }
    end
  end
end
