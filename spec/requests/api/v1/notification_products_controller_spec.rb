require "rails_helper"
require "swagger_helper"

RSpec.describe "API Notification Products Controller", type: :request do
  let(:user) { create(:user, :activated, :with_api_token, has_viewed_introduction: true, team: user_team) }
  let(:user_team) { create(:team) }

  let!(:notification) { create(:notification, :with_business) }
  let!(:product) { create(:product) }

  path "/api/v1/notifications/{notification_id}/products" do
    post "Adds a Product to a Notification" do
      description %{
        Adds a Product to a Notification

        This endpoint allows you to add a product to a notification.
        An email will be sent to the notification owner if the `send_email` parameter is set to `true`, otherwise no email will be sent.
    }
      tags ["Products", "Notifications"]
      security [bearer: []]
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :notification_id, in: :path, type: :string, required: true, description: "Notification ID", example: "1232-434"
      parameter name: :add_product, in: :body, schema: { '$ref' => '#/components/schemas/add_product_to_notification' }

      parameter name: :send_email, in: :path, type: :string, description: "Send a PSD email notification to the owner of Notification", default: "false", required: false

      let(:Authorization) { "Authorization #{user.api_tokens.first&.token}" }
      let(:notification_id) { notification.pretty_id }

      consumes 'application/json'

      request_body_example value: {
        product: {
          id: "123"
        }
      }, name: 'add_product', summary: "An sample product"

      response "201", "Product added to Notification" do
        let(:notification_id) { notification.pretty_id }
        let(:Authorization) { "Authorization #{user.api_tokens.first&.token}" }
        let(:add_product) do
          {
            product: {
              id: product.id
            }
          }
        end

        run_test! do |response|
          expect(response).to have_http_status(:created)
          expect(response.location).to be_present
        end
      end

      response "422", "Notification not found" do
        let(:Authorization) { "Authorization #{user.api_tokens.first&.token}" }
        let(:notification_id) { '12341234' }
        let(:add_product) do
          {
            product: {
              id: product.id
            }
          }
        end

        run_test! do |response|
          json = JSON.parse(response.body, symbolize_names: true)

          expect(json[:error]).to be_present
        end
      end

      response "404", "Product not found" do
        let(:Authorization) { "Authorization #{user.api_tokens.first&.token}" }
        let(:notification_id) { notification.pretty_id }
        let(:add_product) do
          {
            product: {
              id: "23123123"
            }
          }
        end

        run_test! do |response|
          json = JSON.parse(response.body, symbolize_names: true)

          expect(json[:error]).to be_present
        end
      end

      response "401", "Unauthorised user" do
        let(:Authorization) { "Authorization 0000" }
        let(:id) { "invalid" }
        let(:add_product) do
          {
            product: {
              id: "23123123"
            }
          }
        end

        run_test!
      end
    end
  end

end
