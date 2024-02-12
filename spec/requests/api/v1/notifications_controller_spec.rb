require "rails_helper"
require "swagger_helper"

RSpec.describe "API Notifications Controller", type: :request do
  let(:user) { create(:user, :activated, :with_api_token, has_viewed_introduction: true, team: user_team) }
  let(:user_team) { create(:team) }
  let!(:notification) { create(:notification, :with_products, :with_business) }

  path "/api/v1/notifications/{id}" do
    get "Retrieves a Notification" do
      description "Retrieves a Notification's detail by ID"
      tags "Notifications"
      produces "application/json"
      security [bearer: []]
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :id, in: :path, type: :string

      response "200", "Notification found" do
        schema '$ref' => '#/components/schemas/notification_object'

        let(:Authorization) { "Authorization #{user.api_tokens.first&.token}" }

        let(:id) { notification.pretty_id }
        run_test! do |response|
          json = JSON.parse(response.body, symbolize_names: true)

          expect(json[:id]).to eq(notification.pretty_id)
          expect(json[:created_at]).to eq(notification.created_at.xmlschema)
          expect(json[:updated_at]).to eq(notification.updated_at.xmlschema)
        end
      end

      response "404", "Notification not found" do
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
end
