require "rails_helper"

RSpec.describe Match, type: :model do
  let(:rule_set) { RuleSet.create!(name: "European", max_time: 180, best_of_points: 3, draw_system: "ippon") }
  let(:cat)      { Category.first || FactoryBot.create(:category) }
  let(:shiajo)   { Shiajo.create!(name: "Shiajo 1", category: cat) }

  it "applies default values from rule_set" do
    m = described_class.create!(category: cat, shiajo: shiajo, rule_set: rule_set, red_competitor_id: 1, white_competitor_id: 2)
    expect(m.max_time).to eq(180)
    expect(m.best_of_points).to eq(3)
    expect(m.draw_system).to eq("ippon")
  end

  it "starts with status upcoming" do
    m = described_class.create!(category: cat, shiajo: shiajo, rule_set: rule_set, red_competitor_id: 1, white_competitor_id: 2)
    expect(m.status).to eq("upcoming")
  end
end
