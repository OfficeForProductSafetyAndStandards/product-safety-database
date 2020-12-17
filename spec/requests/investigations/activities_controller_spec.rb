require "rails_helper"

RSpec.describe Investigations::ActivitiesController, :with_stubbed_elasticsearch, type: :request do
  let(:product) { create(:product) }
  let(:investigation) { create(:allegation, products: [product]) }
  let!(:audit_activity_test_result) { create(:audit_activity_test_result, investigation: investigation) }

  before { sign_in investigation.owner_user }

  it "renders without errors" do
    get investigation_activity_path(investigation)

    expect(response).to have_http_status(:ok)
  end
end
