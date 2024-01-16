RSpec.describe "Viewing a product owner", type: :request, with_stubbed_mailer: true, with_stubbed_opensearch: true do
  let(:user) { create(:user, :activated) }
  let(:creation_time) { 1.day.ago }

  before do
    travel_to(creation_time { product })
    sign_in user
  end

  context "with a live product" do
    context "with an owner" do
      let(:product) { create(:product, owning_team: user.team) }

      it "responds with a 200 status" do
        get owner_product_path(product)
        expect(response).to have_http_status(:ok)
      end
    end

    context "without an owner" do
      let(:product) { create(:product, owning_team: nil) }

      it "responds with a 404 (not found) status" do
        get owner_product_path(product)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context "with a product attached to a notification" do
    let(:notification) { create(:allegation, creator: user) }
    let(:investigation_product) { notification.investigation_products.create(product:) }

    context "with an open case" do
      context "with an owner" do
        let(:product) { create(:product, owning_team: user.team) }

        it "responds with a 200 status" do
          get owner_investigation_investigation_product_path(notification, investigation_product)
          expect(response).to have_http_status(:ok)
        end
      end

      context "without an owner" do
        let(:product) { create(:product, owning_team: nil) }

        it "responds with a 404 (not found) status" do
          get owner_investigation_investigation_product_path(notification, investigation_product)
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "with a closed case" do
      before do
        ChangeNotificationStatus.call!(notification:, new_status: "closed", user:)
      end

      context "with an owner" do
        let(:product) { create(:product, owning_team: user.team) }

        it "responds with a 200 status" do
          get owner_investigation_investigation_product_path(notification, investigation_product)
          expect(response).to have_http_status(:ok)
        end
      end

      context "without an owner" do
        let(:product) { create(:product, owning_team: nil) }

        it "responds with a 404 (not found) status" do
          get owner_investigation_investigation_product_path(notification, investigation_product)
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
