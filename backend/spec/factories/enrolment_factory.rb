FactoryBot.define do
  factory :enrolment do
    association :competitor
    association :category
  end
end
