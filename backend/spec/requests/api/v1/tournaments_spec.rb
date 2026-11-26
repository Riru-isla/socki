require "rails_helper"

RSpec.describe "Tournaments API", type: :request do
  let(:season) { create(:season) }

  describe "GET /api/v1/tournaments" do
    it "lists tournaments with their season" do
      tournament = create(:tournament, season: season)
      create(:category, tournament: tournament)

      get "/api/v1/tournaments"

      expect(response).to have_http_status(:ok)
      expect(json.size).to eq(1)
      expect(json.first).to include("id" => tournament.id, "category_count" => 1)
      expect(json.first["season"]["name"]).to eq(season.name)
    end
  end

  describe "GET /api/v1/tournaments/:id" do
    it "returns categories with shiajos, enrolments and ordered matches" do
      tournament = create(:tournament, season: season)
      category = create(:category, tournament: tournament)
      shiajo = create(:shiajo, category: category)
      create(:enrolment, category: category)
      second = create(:match, category: category, shiajo: shiajo, position: 2)
      first = create(:match, category: category, shiajo: shiajo, position: 1)

      get "/api/v1/tournaments/#{tournament.id}"

      expect(response).to have_http_status(:ok)
      cat = json["categories"].first
      expect(cat["shiajos"].map { |s| s["id"] }).to eq([ shiajo.id ])
      expect(cat["enrolments"].size).to eq(1)
      expect(cat["matches"].map { |m| m["id"] }).to eq([ first.id, second.id ])
    end

    it "returns 404 for an unknown tournament" do
      get "/api/v1/tournaments/0"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/tournaments" do
    let(:valid) do
      { title: "Open de Valencia", region: "Valencia", tournament_type: "open", official: false,
        starts_on: "2026-05-01", ends_on: "2026-05-02", season_id: season.id }
    end

    it "creates a tournament" do
      post "/api/v1/tournaments", params: { tournament: valid }, as: :json

      expect(response).to have_http_status(:created)
      expect(json).to include("title" => "Open de Valencia", "official" => false, "category_count" => 0)
    end

    it "returns validation errors" do
      post "/api/v1/tournaments", params: { tournament: valid.merge(title: "") }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json["errors"]).to include("Title can't be blank")
    end
  end

  describe "POST /api/v1/tournaments/:tournament_id/categories" do
    let(:tournament) { create(:tournament, season: season) }
    let(:category_type) { create(:category_type) }

    it "creates a category" do
      post "/api/v1/tournaments/#{tournament.id}/categories",
           params: { category: { name: "Senior", category_type_id: category_type.id } }, as: :json

      expect(response).to have_http_status(:created)
      expect(json).to include("name" => "Senior", "shiajo_count" => 0)
      expect(json["category_type"]["id"]).to eq(category_type.id)
    end

    it "rejects a missing category type" do
      post "/api/v1/tournaments/#{tournament.id}/categories", params: { category: { name: "Senior" } }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
