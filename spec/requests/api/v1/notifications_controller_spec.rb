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

  path "/api/v1/notifications" do
    post "Creates a draft Notification" do
      description "Creates a draft Notification in PSD"
      tags "Notifications"
      security [bearer: []]
      parameter name: :Authorization, in: :header, type: :string
      let(:Authorization) { "Authorization #{user.api_tokens.first&.token}" }

      consumes 'application/json'

      request_body_example value: {
        notification: {
          user_title: 'Turbo vac 3000',
          reported_reason: 'non_compliant',
          non_compliant_reason: "No earth pin on mains plug",
        }
      }, name: 'notification', summary: "An non-compliant notification"

      parameter name: :notification, in: :body, schema: { '$ref' => '#/components/schemas/new_notification' }

      response "201", "Notification created" do
        schema '$ref' => '#/components/schemas/notification_object'
        let(:Authorization) { "Authorization #{user.api_tokens.first&.token}" }
        let(:notification) do
          {
            user_title: 'foo',
            reported_reason: 'safe_and_compliant'
          }
        end

        run_test! do |response|
          json = JSON.parse(response.body, symbolize_names: true)

          expect(json[:id]).to be_present
          expect(json[:user_title]).to eq('foo')
          expect(json[:reported_reason]).to eq('safe_and_compliant')
        end
      end

      response "406", "Notification not valid" do
        let(:Authorization) { "Authorization #{user.api_tokens.first&.token}" }
        let(:notification) do
          {
            reported_reason: 'safe_and_compliant',
          }
        end
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
