require "rails_helper"
require "swagger_helper"

RSpec.describe "API auth controller", type: :request do
  let(:user_team) { create(:team) }
  let(:user) { create(:user, :activated, has_viewed_introduction: true, team: user_team) }

  describe "Requesting an API token" do



    context "with invalid credentials" do
      it "returns unauthorized if user is not valid" do
        post api_v1_auth_path do
          tags 'Blogs'
          consumes 'application/json'
          expect(response).to have_http_status(:unauthorized)
        end

      end
    end

    context "with valid credentials" do
      it "returns a token" do
        post api_v1_auth_path, params: { email: user.email, password: user.password }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["token"]).to eq(user.api_tokens.find_or_create_by(name: ApiToken::DEFAULT_NAME).token)
      end
    end
  end
end
