require "rails_helper"

RSpec.describe "Viewing a product owner", type: :request, with_stubbed_mailer: true, with_stubbed_opensearch: true do
  let(:user) { create(:user, :activated) }
  let(:creation_time) { 1.day.ago }
  let(:product) { create(:product, :with_versions, owning_team: user.team) }

  before do
    travel_to creation_time { product }
    sign_in user
  end

  context "with timestamp", :with_errors_rendered do
    context "with invalid timestamp" do
      before { get product_owner_path(product, timestamp: "invalid") }

      it "responds with a 404 (not found) status" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with timestamp prior to creation date" do
      before { get product_owner_path(product, timestamp: 2.days.ago.to_i) }

      it "responds with a 404 (not found) status" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with timestamp valid for previous version" do
      before { get product_owner_path(product, timestamp: creation_time.to_i) }

      it "responds with a 200 status" do
        expect(response).to have_http_status(:ok)
      end
    end

    context "with timestamp valid for current version" do
      before { get product_owner_path(product, timestamp: Time.zone.now.to_i) }

      it "responds with a 200 status" do
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context "without an owner", :with_errors_rendered do
    let(:product) { create(:product, :with_versions, owning_team: nil) }

    context "with timestamp valid for previous version" do
      before { get product_owner_path(product, timestamp: creation_time.to_i) }

      it "responds with a 404 (not found) status" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with timestamp valid for current version" do
      before { get product_owner_path(product, timestamp: Time.zone.now.to_i) }

      it "responds with a 404 (not found) status" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
