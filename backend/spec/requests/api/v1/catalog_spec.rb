require "rails_helper"

# Small CRUD endpoints used by the setup wizard and admin screens.
RSpec.describe "Catalog APIs", type: :request do
  describe "disciplines and rule sets" do
    it "lists disciplines by name" do
      create(:discipline, name: "Kendo")
      create(:discipline, name: "Iaido")

      get "/api/v1/disciplines"

      expect(json.map { |d| d["name"] }).to eq(%w[Iaido Kendo])
    end

    it "lists rule sets" do
      create(:rule_set, name: "European", max_time: 180)

      get "/api/v1/rule_sets"

      expect(json.first).to include("name" => "European", "max_time" => 180, "best_of_points" => 3, "draw_system" => "ippon")
    end
  end

  describe "seasons" do
    let(:discipline) { create(:discipline, name: "Kendo") }

    it "creates and lists seasons" do
      post "/api/v1/seasons", params: { season: { name: "Kendo 2027", discipline_id: discipline.id } }, as: :json
      expect(response).to have_http_status(:created)

      get "/api/v1/seasons"
      expect(json.first).to include("name" => "Kendo 2027", "discipline" => "Kendo")
    end

    it "rejects a season without discipline" do
      post "/api/v1/seasons", params: { season: { name: "Orphan" } }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "category types" do
    it "creates and lists category types" do
      post "/api/v1/category_types", params: { category_type: { name: "Veteranos", gender: "mixed", team: false } }, as: :json
      expect(response).to have_http_status(:created)

      get "/api/v1/category_types"
      expect(json.first).to include("name" => "Veteranos", "gender" => "mixed", "team" => false)
    end

    it "rejects an unknown gender" do
      post "/api/v1/category_types", params: { category_type: { name: "X", gender: "other" } }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "competitors" do
    it "creates, lists and deletes competitors" do
      post "/api/v1/competitors", params: { competitor: { name: "Hiro Sato", age: 22, province: "Barcelona" } }, as: :json
      expect(response).to have_http_status(:created)
      id = json["id"]

      get "/api/v1/competitors"
      expect(json.map { |c| c["name"] }).to eq([ "Hiro Sato" ])

      delete "/api/v1/competitors/#{id}"
      expect(response).to have_http_status(:no_content)
      expect(Competitor.exists?(id)).to be(false)
    end

    it "rejects a blank name" do
      post "/api/v1/competitors", params: { competitor: { name: "" } }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "enrolments" do
    let(:category) { create(:category) }
    let(:competitor) { create(:competitor, name: "Aiko Fujimoto") }

    it "enrols, lists and removes a competitor" do
      post "/api/v1/categories/#{category.id}/enrolments",
           params: { enrolment: { competitor_id: competitor.id, seed: 1 } }, as: :json
      expect(response).to have_http_status(:created)
      expect(json).to include("seed" => 1)
      id = json["id"]

      get "/api/v1/categories/#{category.id}/enrolments"
      expect(json.map { |e| e["competitor"]["name"] }).to eq([ "Aiko Fujimoto" ])

      delete "/api/v1/enrolments/#{id}"
      expect(response).to have_http_status(:no_content)
    end

    it "rejects a duplicate enrolment" do
      create(:enrolment, category: category, competitor: competitor)

      post "/api/v1/categories/#{category.id}/enrolments",
           params: { enrolment: { competitor_id: competitor.id } }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json["errors"].join).to match(/already enrolled/)
    end
  end
end
