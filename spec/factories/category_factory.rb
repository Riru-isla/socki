FactoryBot.define do
  factory :category do
    name { "Masculino Individual" }
    association :tournament
    association :category_type
  end
end
