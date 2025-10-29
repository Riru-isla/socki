require "rails_helper"

RSpec.describe Competitor, type: :model do
  it "is valid with name" do
    c = described_class.new(name: "Yamato Tanaka", age: 27, province: "Madrid")
    expect(c).to be_valid
  end

  it "is invalid without name" do
    c = described_class.new
    expect(c).to be_invalid
    expect(c.errors[:name]).to be_present
  end
end
