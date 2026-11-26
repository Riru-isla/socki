require "rails_helper"

RSpec.describe "POST /api/v1/matches/:match_id/match_events", type: :request do
  let(:match) { create(:match, status: "in_progress") }
  let(:red) { match.red_competitor }
  let(:white) { match.white_competitor }

  def post_event(competitor_id:, side:, event_type: "men", at_second: "01:32.450")
    post "/api/v1/matches/#{match.id}/match_events",
         params: { event: { competitor_id: competitor_id, side: side, event_type: event_type, at_second: at_second } },
         as: :json
  end

  it "records a scoring event and returns the updated match" do
    post_event(competitor_id: red.id, side: "red")

    expect(response).to have_http_status(:ok)
    expect(json["ok"]).to be(true)
    expect(json["match"]["score"]).to eq("red" => 1, "white" => 0)
    event = json["match"]["events"].last
    expect(event).to include("side" => "red", "event_type" => "men", "at_second" => "01:32.450", "point_index_for_side" => 1)
  end

  it "numbers points per side" do
    post_event(competitor_id: red.id, side: "red")
    post_event(competitor_id: white.id, side: "white", event_type: "kote")
    post_event(competitor_id: red.id, side: "red", event_type: "do")

    expect(json["match"]["score"]).to eq("red" => 2, "white" => 1)
    expect(match.match_events.where(side: "red").order(:id).pluck(:point_index_for_side)).to eq([ 1, 2 ])
  end

  it "does not score or number a penalty" do
    post_event(competitor_id: red.id, side: "red", event_type: "hansoku")

    expect(response).to have_http_status(:ok)
    expect(json["match"]["score"]).to eq("red" => 0, "white" => 0)
    expect(json["match"]["events"].last["point_index_for_side"]).to be_nil
  end

  it "broadcasts the updated match to the match stream" do
    expect {
      post_event(competitor_id: red.id, side: "red")
    }.to have_broadcasted_to("match_#{match.id}").with(a_hash_including("score" => { "red" => 1, "white" => 0 }))
  end

  it "rejects a competitor who is not in the match" do
    outsider = create(:competitor)
    expect {
      post_event(competitor_id: outsider.id, side: "red")
    }.not_to change(MatchEvent, :count)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(json["error"]).to include("does not belong")
  end

  it "rejects an invalid side" do
    post_event(competitor_id: red.id, side: "blue")

    expect(response).to have_http_status(:unprocessable_entity)
    expect(json["ok"]).to be(false)
  end

  it "returns 404 for an unknown match" do
    post "/api/v1/matches/0/match_events",
         params: { event: { competitor_id: red.id, side: "red", event_type: "men" } }, as: :json
    expect(response).to have_http_status(:not_found)
  end
end
