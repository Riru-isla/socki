FactoryBot.define do
  factory :tournament do
    title { "Campeonato de Madrid 2025" }
    region { "Madrid" }
    official { true }
    tournament_type { "regional_championship" }
    starts_on { Date.new(2025,3,21) }
    ends_on   { Date.new(2025,3,22) }

    association :season
  end
end
