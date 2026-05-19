require "rails_helper"

RSpec.describe Match, "#propagate_winner_to_downstream_matches", type: :model do
  let(:category) { create(:category) }
  let(:shiajo)   { create(:shiajo, category: category) }
  let(:rule_set) { create(:rule_set) }
  let(:a) { create(:competitor, name: "A") }
  let(:b) { create(:competitor, name: "B") }
  let(:c) { create(:competitor, name: "C") }
  let(:d) { create(:competitor, name: "D") }

  it "fills the red competitor of a match that lists this one as red_source_match" do
    semi = create(:match, category: category, shiajo: shiajo, rule_set: rule_set, red_competitor: a, white_competitor: b)
    final = create(:match, category: category, shiajo: shiajo, rule_set: rule_set, red_competitor: nil, white_competitor: nil, red_source_match: semi)

    semi.update!(winner: a)

    expect(final.reload.red_competitor).to eq(a)
    expect(final.white_competitor).to be_nil
  end

  it "fills the white competitor of a match that lists this one as white_source_match" do
    semi = create(:match, category: category, shiajo: shiajo, rule_set: rule_set, red_competitor: c, white_competitor: d)
    final = create(:match, category: category, shiajo: shiajo, rule_set: rule_set, red_competitor: nil, white_competitor: nil, white_source_match: semi)

    semi.update!(winner: d)

    expect(final.reload.white_competitor).to eq(d)
    expect(final.red_competitor).to be_nil
  end

  it "fills both sides of a final from two upstream matches" do
    semi1 = create(:match, category: category, shiajo: shiajo, rule_set: rule_set, red_competitor: a, white_competitor: b)
    semi2 = create(:match, category: category, shiajo: shiajo, rule_set: rule_set, red_competitor: c, white_competitor: d)
    final = create(:match, category: category, shiajo: shiajo, rule_set: rule_set, red_competitor: nil, white_competitor: nil, red_source_match: semi1, white_source_match: semi2)

    semi1.update!(winner: a)
    semi2.update!(winner: d)

    final.reload
    expect(final.red_competitor).to eq(a)
    expect(final.white_competitor).to eq(d)
  end

  it "is a no-op when winner_id is cleared back to nil" do
    semi = create(:match, category: category, shiajo: shiajo, rule_set: rule_set, red_competitor: a, white_competitor: b)
    final = create(:match, category: category, shiajo: shiajo, rule_set: rule_set, red_competitor: nil, white_competitor: nil, red_source_match: semi)

    semi.update!(winner: a)
    expect(final.reload.red_competitor).to eq(a)

    # clearing the winner doesn't roll back the propagation (intentional —
    # downstream slot is already locked in once it's been set)
    semi.update!(winner_id: nil)
    expect(final.reload.red_competitor).to eq(a)
  end
end
