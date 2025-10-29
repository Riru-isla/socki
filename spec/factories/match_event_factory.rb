FactoryBot.define do
  factory :match_event do
    association :match
    association :competitor

    side { "red" }
    event_type { "men" }
    at_second { 42 }
    point_index_for_side { 1 }
    match_winning { false }

    # The match_event table stores competitor_id (integer), not belongs_to competitor,
    # so we need to override after build:
    after(:build) do |event, ctx|
      event.competitor_id ||= ctx.competitor.id
    end
  end
end
