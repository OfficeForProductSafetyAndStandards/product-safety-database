require "rails_helper"

RSpec.describe Investigations::ActivitiesController, :with_stubbed_elasticsearch, type: :request do
  let(:product)       { create(:product) }
  let(:investigation) { create(:allegation, products: [product]) }
  let(:legacy_title)  { "legacy title" }
  let!(:legacy_audit_activity_test_result) do
    create(:legacy_audit_activity_test_result, title: legacy_title, investigation: investigation)
  end

  before { sign_in investigation.owner_user }

  context "with legacy audit" do
    it "renders without errors", :aggregate_failures do
      get investigation_activity_path(investigation)

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(legacy_audit_activity_test_result.title)
    end
  end
end
