require "rails_helper"
require "swagger_helper"

RSpec.describe "API Products Controller", type: :request do
  let(:user) { create(:user, :activated, :with_api_token, has_viewed_introduction: true, team: user_team) }
  let(:user_team) { create(:team) }

  path "/api/v1/products/{id}" do
    get "Retrieves a Product" do
      description "Retrieves a Product's detail by ID"
      tags "Products"
      produces "application/json"
      security [bearer: []]
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :id, in: :path, type: :string

      response "200", "Product found" do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 name: { type: :string },
                 brand: { type: :string },
                 product_code: { type: :string },
                 barcode: { type: :string, nullable: true },
                 category: { type: :string },
                 subcategory: { type: :string, nullable: true },
                 description: { type: :string },
                 country_of_origin: { type: :string },
                 webpage: { type: :string },
                 owning_team: { type: :object,
                                properties: {
                                  name: { type: :string },
                                  email: { type: :string },
                                } },
                 product_images: { type: :array, items: { type: :object, properties: { url: { type: :string } } } },
               },
               required: %w[name]


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
    post "Creates a Product" do
      description "Creates a Product"
      tags "Products"
      produces "application/json"
      security [bearer: []]

    end
  end

end



