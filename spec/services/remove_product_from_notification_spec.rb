require "rails_helper"

RSpec.describe RemoveProductFromNotification, :with_test_queue_adapter do
  subject(:result) do
    described_class.call(notification:, investigation_product:, user:, reason:)
  end

  let(:notification) { create(:notification, products: [product], creator:) }
  let(:product) { create(:product_washing_machine, owning_team: creator.team) }
  let(:investigation_product) { notification.investigation_products.first }
  let(:reason)        { Faker::Hipster.sentence }
  let(:user)          { create(:user, :opss_user) }
  let(:creator)       { user }
  let(:owner)         { user }

  def expected_email_subject
    "Notification updated"
  end

  def expected_email_body(name)
    "Product was removed from the notification by #{name}."
  end

  context "with stubbed opensearch", :with_stubbed_opensearch do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no investigation parameter" do
      let(:result) { described_class.call(product:, user:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no product parameter" do
      let(:result) { described_class.call(notification:, user:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      let(:result) { described_class.call(notification:, product:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with required parameters" do
      context "when notification has not been closed while product was linked to it" do
        it "returns success" do
          expect(result).to be_success
        end

        it "removes the product from the notification" do
          result
          expect(notification.reload.products).not_to include(product)
        end

        it "creates an audit activity", :aggregate_failures do
          result
          activity = notification.reload.activities.find_by!(type: AuditActivity::Product::Destroy.name)
          expect(activity).to have_attributes(title: nil, body: nil, investigation_product_id: investigation_product.id, metadata: { "reason" => reason, "product" => JSON.parse(product.reload.attributes.to_json) })
          expect(activity.added_by_user).to eq(user)
        end

        it_behaves_like "a service which notifies the notification owner"
      end

      context "when notification has been closed while product was linked to it" do
        before do
          ChangeNotificationStatus.call!(notification:, new_status: "closed", user:)
        end

        it "returns failure" do
          result = described_class.call(notification: notification.reload, investigation_product: investigation_product.reload, user:, reason:)
          expect(result).to be_failure
        end

        it "does not remove the product from the notification" do
          described_class.call(notification: notification.reload, investigation_product: investigation_product.reload, user:, reason:)
          expect(notification.reload.products).to include(product)
        end
      end

      it "creates an audit activity", :aggregate_failures do # rubocop:disable RSpec/ExampleLength
        result
        activity = notification.reload.activities.find_by!(type: AuditActivity::Product::Destroy.name)
        expect(activity).to have_attributes(
          title: nil,
          body: nil,
          investigation_product_id: investigation_product.id,
          metadata: {
            "reason" => reason,
            "product" => JSON.parse(product.reload.attributes.to_json)
          }
        )
        expect(activity.added_by_user).to eq(user)
      end

      it "sets the product to unowned" do
        result
        expect(product.reload.owning_team).to be_nil
      end

      it_behaves_like "a service which notifies the notification owner"

      context "when the product is owned by another team" do
        let(:product) { create(:product_washing_machine, owning_team: create(:team)) }

        it "does not change the product's ownership", :aggregate_failures do
          result
          product.reload
          expect(product.owning_team).not_to eq(notification.owner_team)
          expect(product.owning_team).not_to be_nil
        end
      end

      context "when the product is linked to another of its owning team's notifications" do
        before do
          create :allegation, products: [product], creator:
        end

        it "does not change the product's ownership" do
          result
          expect(product.reload.owning_team).to eq(notification.owner_team)
        end
      end
    end
  end
end
