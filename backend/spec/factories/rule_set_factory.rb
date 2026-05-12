FactoryBot.define do
  factory :rule_set do
    sequence(:name) { |n| "RuleSet #{n}" }
    max_time { 180 }
    best_of_points { 3 }
    draw_system { "ippon" }
  end
end
