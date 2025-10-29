FactoryBot.define do
  factory :shiajo do
    sequence(:name) { |n| "Shiajo #{n}" }
    association :category
    active { true }
    current_match_id { nil }
  end
end
