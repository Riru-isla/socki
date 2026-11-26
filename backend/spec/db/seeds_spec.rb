require "rails_helper"

RSpec.describe "db/seeds.rb" do
  def run_seeds
    expect { load Rails.root.join("db/seeds.rb") }.to output.to_stdout
  end

  it "builds a mid-tournament snapshot with two live shiajos" do
    run_seeds

    expect(Tournament.count).to eq(1)
    expect(Shiajo.count).to eq(2)
    expect(Match.count).to eq(10)
    expect(Enrolment.count).to eq(12)

    Shiajo.find_each do |shiajo|
      expect(shiajo.matches.in_progress.count).to eq(1)
      expect(shiajo.current_match).to be_in_progress
      expect(Shiajos::ProjectorPayload.new(shiajo).call.mode).to eq(:in_progress)
    end
  end

  it "is idempotent" do
    run_seeds
    counts = [ Competitor, Enrolment, Match, MatchEvent ].map(&:count)

    run_seeds

    expect([ Competitor, Enrolment, Match, MatchEvent ].map(&:count)).to eq(counts)
  end
end
