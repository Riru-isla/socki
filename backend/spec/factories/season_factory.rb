FactoryBot.define do
  factory :season do
    name { "Kendo 2025" }
    year { 2025 }
    association :discipline
  end
end
