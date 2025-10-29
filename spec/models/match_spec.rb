require "rails_helper"

RSpec.describe Match, type: :model do
  let(:rule_set) { create(:rule_set) }
  let(:category) { create(:category) }
  let(:shiajo)   { create(:shiajo, category: category) }

  it "applies default values from rule_set" do
    m = described_class.create!(
      category: category,
      shiajo: shiajo,
      rule_set: rule_set,
      red_competitor: create(:competitor),
      white_competitor: create(:competitor)
    )

    expect(m.max_time).to eq(rule_set.max_time)
    expect(m.best_of_points).to eq(rule_set.best_of_points)
    expect(m.draw_system).to eq(rule_set.draw_system)
  end

  it "starts with status upcoming" do
    m = described_class.create!(
      category: category,
      shiajo: shiajo,
      rule_set: rule_set,
      red_competitor: create(:competitor),
      white_competitor: create(:competitor)
    )

    expect(m.status).to eq("upcoming")
    expect(m).to be_upcoming
  end
end
