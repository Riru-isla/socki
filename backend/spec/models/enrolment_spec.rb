require "rails_helper"

RSpec.describe Enrolment, type: :model do
  it "is valid with a competitor and a category" do
    expect(build(:enrolment)).to be_valid
  end

  it "is invalid without a competitor" do
    e = build(:enrolment, competitor: nil)
    expect(e).to be_invalid
    expect(e.errors[:competitor]).to be_present
  end

  it "is invalid without a category" do
    e = build(:enrolment, category: nil)
    expect(e).to be_invalid
    expect(e.errors[:category]).to be_present
  end

  it "cannot enrol the same competitor twice in the same category" do
    competitor = create(:competitor)
    category = create(:category)
    create(:enrolment, competitor: competitor, category: category)

    duplicate = build(:enrolment, competitor: competitor, category: category)
    expect(duplicate).to be_invalid
    expect(duplicate.errors[:competitor_id]).to be_present
  end

  it "allows the same competitor in different categories" do
    competitor = create(:competitor)
    create(:enrolment, competitor: competitor, category: create(:category))

    other = build(:enrolment, competitor: competitor, category: create(:category))
    expect(other).to be_valid
  end
end
