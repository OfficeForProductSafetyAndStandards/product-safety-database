require "rails_helper"
require "swagger_helper"

RSpec.describe "API Notifications Controller",  :with_opensearch, type: :request do
  let(:user) { create(:user, :activated, :with_api_token, has_viewed_introduction: true, team: user_team) }
  let(:user_team) { create(:team) }
  let!(:notification) { create(:notification, :with_products, :with_business, user_title: notification_title) }
  let(:notification_title) { "Turbo vac 3000" }

  before do
    Investigation.reindex
  end

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

        after do |example|
          content = example.metadata[:response][:content] || {}
          example_spec = {
            "application/json"=>{
              examples: {
                test_example: {
                  value: JSON.parse(response.body, symbolize_names: true)
                }
              }
            }
          }
          example.metadata[:response][:content] = content.deep_merge(example_spec)
        end

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
    get "Search for Notifications" do
      description %{
Search for a Product

* The search `q` query performs a full text search on the notificaiton title and product name. It uses the same code as the search bar in the UI within PSD.

* The `sort_by` parameter can be used to sort the results. The default is `updated_at` which returns the most recent updated notification first. The `sort_dir` parameter can be used to sort the results in ascending or descending order. The default is descending.
* The `category` parameter can be used to filter the results by category. If given, only products in this category will be returned.
* The `page` parameter can be used to paginate the results. By default, 20 results are returned per page.
}
      tags "Notifications"
      produces "application/json"
      security [bearer: []]
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :q, in: :query, type: :string, description: "Search query. Searches based on name, description, brand, PSD ID, and product_code"
      parameter name: :sort_by, in: :query, required: false, type: :string, description: "Sort by parameter. Choose name, updated_at, or relevant. Default is updated_at"
      parameter name: :sort_dir, in: :query, required: false, type: :string, description: "Sort direction. Choose asc or desc. Default is desc"

      parameter name: :page, required: false, in: :query, type: :integer, description: "Page number"

      response "200", "Search results returned" do
        let(:Authorization) { "Authorization #{user.api_tokens.first&.token}" }
        let(:q) { notification_title }

        after do |example|
          content = example.metadata[:response][:content] || {}
          example_spec = {
            "application/json"=>{
              examples: {
                test_example: {
                  value: JSON.parse(response.body, symbolize_names: true)
                }
              }
            }
          }
          example.metadata[:response][:content] = content.deep_merge(example_spec)
        end

        run_test! do |response|
          expect(response).to have_http_status(:ok)

          json = JSON.parse(response.body, symbolize_names: true)

          expect(json[:notifications].count).to eq(1)
          expect(json[:notifications].first[:id]).to eq(notification.pretty_id)
        end
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
