FactoryBot.define do
  factory :competitor do
    sequence(:name) { |n| "Competitor #{n}" }
    age { 28 }
    province { "Madrid" }
  end
end
