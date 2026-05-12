require "rails_helper"

RSpec.describe MatchEvent, type: :model do
  let(:match) { create(:match) }

  it "is valid with minimal data" do
    e = described_class.new(
      match: match,
      competitor_id: match.red_competitor_id,
      side: "red",
      event_type: "men"
    )
    expect(e).to be_valid
  end

  it "requires side, event_type, competitor" do
    e = described_class.new(match: match)
    expect(e).not_to be_valid
    expect(e.errors.attribute_names).to include(:side, :event_type, :competitor_id)
  end
end
