require "rails_helper"

RSpec.describe "Auth (Devise, JSON)", type: :request do
  it "signs up a user" do
    post "/api/v1/auth", params: { user: { email: "new@socki.app", password: "password123" } }, as: :json

    expect(response).to have_http_status(:created)
    expect(json).to include("email" => "new@socki.app", "is_admin" => false)
  end

  it "rejects an invalid sign up" do
    post "/api/v1/auth", params: { user: { email: "bad", password: "x" } }, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(json["errors"]).to be_present
  end

  it "signs in and out" do
    User.create!(email: "admin@socki.app", password: "password123", is_admin: true)

    post "/api/v1/auth/sign_in", params: { user: { email: "admin@socki.app", password: "password123" } }, as: :json
    expect(response).to have_http_status(:ok)
    expect(json).to include("email" => "admin@socki.app", "is_admin" => true)

    delete "/api/v1/auth/sign_out", as: :json
    expect(response).to have_http_status(:no_content)
  end

  it "rejects a wrong password" do
    User.create!(email: "admin@socki.app", password: "password123")

    post "/api/v1/auth/sign_in", params: { user: { email: "admin@socki.app", password: "nope" } }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end
end
