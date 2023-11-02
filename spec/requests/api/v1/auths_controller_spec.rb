require "rails_helper"
require "swagger_helper"

RSpec.describe "API auth controller", type: :request do
  let(:user) { create(:user, :activated, has_viewed_introduction: true, team: user_team) }
  let(:user_team) { create(:team) }

  path "/api/v1/auth" do
    post "Request an API token" do
      tags "Request an API token"
      consumes "application/json"
      parameter name: :email, in: :query, type: :string
      parameter name: :password, in: :query, type: :string

      response "200", "User authenticated and API token returned" do
        let(:email) { user.email }
        let(:password) { user.password }
        run_test! do |response|
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)["token"]).to eq(user.api_tokens.find_or_create_by(name: ApiToken::DEFAULT_NAME).token)
        end
      end

      response "401", "Unauthorized" do
        let(:email) { "invalid@email.com" }
        let(:password) { "invalid_password" }
        run_test! do |response|
          expect(response).to have_http_status(:unauthorized)
          expect(JSON.parse(response.body)["error"]).to eq("Invalid login")
        end
      end
    end

  end
end
