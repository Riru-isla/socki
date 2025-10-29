require "rails_helper"

RSpec.describe RuleSet, type: :model do
  it "is valid with all required fields" do
    rs = described_class.new(name: "European", max_time: 180, best_of_points: 3, draw_system: "ippon")
    expect(rs).to be_valid
  end

  it "requires all attributes" do
    rs = described_class.new
    expect(rs).to be_invalid
    expect(rs.errors.attribute_names).to include(:name, :max_time, :best_of_points, :draw_system)
  end
end
