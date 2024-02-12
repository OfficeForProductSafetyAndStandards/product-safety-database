require "rails_helper"
require "swagger_helper"

RSpec.describe "API Products Controller", type: :request do
  let(:user) { create(:user, :activated, :with_api_token, has_viewed_introduction: true, team: user_team) }
  let(:user_team) { create(:team) }
  let(:product) { create(:product) }

  path "/api/v1/products/{id}" do
    get "Retrieves a Product" do
      description "Retrieves a Product's detail by ID"
      tags "Products"
      produces "application/json"
      security [bearer: []]
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :id, in: :path, type: :string

      response "200", "Product found" do
        schema '$ref' => '#/components/schemas/product_object'

        let(:Authorization) { "Authorization #{user.api_tokens.first&.token}" }

        let(:id) { create(:product).id }
        run_test! do |response|

        end
      end

      response "404", "Product not found" do
        let(:Authorization) { "Authorization #{user.api_tokens.first&.token}" }
        let(:id) { "invalid" }
        run_test!
      end

      response "401", "Unauthorised user" do
        let(:Authorization) { "Authorization 0000" }
        let(:id) { "invalid" }
        run_test!
      end
    end
  end

  path "/api/v1/products" do
    get "Search for a Product" do
      description "Search for a Product"
      tags "Products"
      produces "application/json"
      security [bearer: []]
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :q, in: :query, type: :string

      response "200", "Search results returned" do
        let(:Authorization) { "Authorization #{user.api_tokens.first&.token}" }
        let(:q) { product.name }

        run_test! do |response|
          expect(response).to have_http_status(:ok)
          #binding.pry
          #expect(JSON.parse(response.body)["token"]).to eq(user.api_tokens.find_or_create_by(name: ApiToken::DEFAULT_NAME).token)
        end
      end
    end
  end

  path "/api/v1/products" do
    post "Creates a Product" do
      description "Creates a Product"
      tags "Products"
      produces "application/json"
      security [bearer: []]
    end
  end
end
