FactoryBot.define do
  factory :category_type do
    sequence(:name) { |n| "Category Type #{n}" }
    gender { "male" }
    team { false }
  end
end
