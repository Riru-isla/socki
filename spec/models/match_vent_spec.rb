require "rails_helper"

RSpec.describe MatchEvent, type: :model do
  let(:rule_set) { RuleSet.create!(name: "European", max_time: 180, best_of_points: 3, draw_system: "ippon") }
  let(:cat)      { Category.first || FactoryBot.create(:category) }
  let(:shiajo)   { Shiajo.create!(name: "Shiajo 1", category: cat) }
  let(:match)    { Match.create!(category: cat, shiajo: shiajo, rule_set: rule_set, red_competitor_id: 1, white_competitor_id: 2) }

  it "is valid with minimal data" do
    e = described_class.new(match: match, competitor_id: 1, side: "red", event_type: "men")
    expect(e).to be_valid
  end

  it "requires side and event_type" do
    e = described_class.new(match: match)
    expect(e).to be_invalid
    expect(e.errors.keys).to include(:side, :event_type, :competitor_id)
  end
end
