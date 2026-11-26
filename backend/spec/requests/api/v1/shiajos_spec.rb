require "rails_helper"

RSpec.describe "Shiajos API", type: :request do
  let(:category) { create(:category) }
  let(:shiajo) { create(:shiajo, category: category) }

  def match_on_shiajo(**attrs)
    create(:match, category: category, shiajo: shiajo, **attrs)
  end

  describe "GET /api/v1/shiajos/:id/projector" do
    it "is in standby when nothing has started" do
      upcoming = match_on_shiajo(position: 1)

      get "/api/v1/shiajos/#{shiajo.id}/projector"

      expect(response).to have_http_status(:ok)
      expect(json["mode"]).to eq("standby")
      expect(json["current_match"]).to be_nil
      expect(json["next_two"].map { |m| m["id"] }).to eq([ upcoming.id ])
    end

    it "shows the live match, the next two after it and the last finished one" do
      finished = match_on_shiajo(position: 1, status: "finished", ended_at: 5.minutes.ago)
      live     = match_on_shiajo(position: 2, status: "in_progress", started_at: 1.minute.ago)
      next1    = match_on_shiajo(position: 3)
      next2    = match_on_shiajo(position: 4)
      match_on_shiajo(position: 5)

      get "/api/v1/shiajos/#{shiajo.id}/projector"

      expect(json["mode"]).to eq("in_progress")
      expect(json["current_match"]["id"]).to eq(live.id)
      expect(json["current_match"]["red"]).to include("id", "name")
      expect(json["next_two"].map { |m| m["id"] }).to eq([ next1.id, next2.id ])
      expect(json["just_finished"]["id"]).to eq(finished.id)
    end

    it "reports match_finished when only finished matches remain live-less" do
      match_on_shiajo(position: 1, status: "finished", ended_at: 1.minute.ago)

      get "/api/v1/shiajos/#{shiajo.id}/projector"

      expect(json["mode"]).to eq("match_finished")
    end
  end

  describe "GET /api/v1/shiajos/:id/summary" do
    it "returns current, recently finished and upcoming matches" do
      match_on_shiajo(position: 1, status: "finished")
      live = match_on_shiajo(position: 2, status: "in_progress")
      match_on_shiajo(position: 3)

      get "/api/v1/shiajos/#{shiajo.id}/summary"

      expect(response).to have_http_status(:ok)
      expect(json["shiajo"]["id"]).to eq(shiajo.id)
      expect(json["current_match"]["id"]).to eq(live.id)
      expect(json["current_match"]["score"]).to eq("red" => 0, "white" => 0)
      expect(json["just_finished"]).to be_present
      expect(json["next_matches"].size).to eq(1)
    end
  end

  describe "POST /api/v1/categories/:category_id/shiajos" do
    it "creates a shiajo" do
      post "/api/v1/categories/#{category.id}/shiajos", params: { shiajo: { name: "Shiajo C", position: 3 } }, as: :json

      expect(response).to have_http_status(:created)
      expect(json).to include("name" => "Shiajo C", "active" => true)
    end

    it "rejects a blank name" do
      post "/api/v1/categories/#{category.id}/shiajos", params: { shiajo: { name: "" } }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
