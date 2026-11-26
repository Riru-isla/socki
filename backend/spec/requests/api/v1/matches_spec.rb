require "rails_helper"

RSpec.describe "Matches API", type: :request do
  describe "GET /api/v1/matches/:id" do
    it "returns the full match payload" do
      match = create(:match)
      match.match_events.create!(competitor_id: match.red_competitor_id, side: "red", event_type: "men", at_second: "00:42.000")

      get "/api/v1/matches/#{match.id}"

      expect(response).to have_http_status(:ok)
      expect(json.keys).to contain_exactly("id", "status", "shiajo", "category", "rule_set", "competitors", "score", "events")
      expect(json["competitors"]["red"]["id"]).to eq(match.red_competitor_id)
      expect(json["score"]).to eq("red" => 1, "white" => 0)
      expect(json["events"].size).to eq(1)
    end
  end

  describe "POST /api/v1/categories/:category_id/matches" do
    let(:category) { create(:category) }
    let(:shiajo) { create(:shiajo, category: category) }
    let(:rule_set) { create(:rule_set, max_time: 240) }
    let(:red) { create(:competitor) }
    let(:white) { create(:competitor) }

    it "creates a match, takes defaults from the rule set and auto-assigns position" do
      create(:match, category: category, shiajo: shiajo, position: 4)

      post "/api/v1/categories/#{category.id}/matches",
           params: { match: { shiajo_id: shiajo.id, rule_set_id: rule_set.id, red_competitor_id: red.id, white_competitor_id: white.id } },
           as: :json

      expect(response).to have_http_status(:created)
      expect(json).to include("position" => 5, "status" => "upcoming")
      expect(json["red_competitor"]["id"]).to eq(red.id)
      expect(Match.find(json["id"]).max_time).to eq(240)
    end

    it "accepts source matches and fills in the winner when it is decided" do
      qf1 = create(:match, category: category, shiajo: shiajo, position: 1)
      qf2 = create(:match, category: category, shiajo: shiajo, position: 2)

      post "/api/v1/categories/#{category.id}/matches",
           params: { match: { shiajo_id: shiajo.id, rule_set_id: rule_set.id, red_source_match_id: qf1.id, white_source_match_id: qf2.id } },
           as: :json

      expect(response).to have_http_status(:created)
      final = Match.find(json["id"])
      expect(final.red_competitor_id).to be_nil

      qf1.update!(winner_id: qf1.white_competitor_id, status: "finished")
      qf2.update!(winner_id: qf2.red_competitor_id, status: "finished")

      final.reload
      expect(final.red_competitor_id).to eq(qf1.white_competitor_id)
      expect(final.white_competitor_id).to eq(qf2.red_competitor_id)
    end

    it "returns errors when the rule set is missing" do
      post "/api/v1/categories/#{category.id}/matches",
           params: { match: { shiajo_id: shiajo.id } }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json["errors"]).to be_present
    end
  end
end
