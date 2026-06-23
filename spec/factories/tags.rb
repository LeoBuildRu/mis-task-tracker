FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "tag_#{n}" }
    system { false }
  end
end
