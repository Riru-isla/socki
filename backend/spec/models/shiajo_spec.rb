require "rails_helper"

RSpec.describe Shiajo, type: :model do
  let(:category) { create(:category) }

  it "is valid with a name and category" do
    s = described_class.new(name: "Shiajo 9", category: category)
    expect(s).to be_valid
  end

  it "requires a name" do
    s = described_class.new(category: category)
    expect(s).not_to be_valid
    expect(s.errors[:name]).to be_present
  end
end
