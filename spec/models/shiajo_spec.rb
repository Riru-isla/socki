require "rails_helper"

RSpec.describe Shiajo, type: :model do
  let(:cat) { Category.first || FactoryBot.create(:category) }

  it "is valid with a name and category" do
    s = described_class.new(name: "Shiajo 1", category: cat)
    expect(s).to be_valid
  end

  it "requires a name" do
    s = described_class.new(category: cat)
    expect(s).to be_invalid
    expect(s.errors[:name]).to be_present
  end
end
