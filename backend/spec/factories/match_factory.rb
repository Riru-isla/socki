FactoryBot.define do
  factory :match do
    association :category
    association :shiajo
    association :rule_set

    # competitors
    association :red_competitor,  factory: :competitor
    association :white_competitor, factory: :competitor

    # these will normally be set by callback, but we set defaults so validation passes
    max_time { 180 }
    best_of_points { 3 }
    draw_system { "ippon" }

    status { "upcoming" }
    started_at { nil }
    ended_at { nil }
    winner_id { nil }
  end
end
