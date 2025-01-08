require "rails_helper"

RSpec.describe AddProductToNotification, :with_test_queue_adapter do
  let(:user) { create(:user, :opss_user) }
  let(:notification) { create(:notification, creator: user) }
  let(:product) { create(:product) }

  context "with no parameters" do
    let(:result) { described_class.call }

    it "returns a failure" do
      expect(result).to be_failure
    end
  end

  context "with no user parameter" do
    let(:result) { described_class.call(notification:, product:) }

    it "returns a failure", :aggregate_failures do
      expect(result).to be_failure
      expect(result.error).to eq("No user supplied")
    end
  end

  context "with no notification parameter" do
    let(:result) { described_class.call(user:, product:) }

    it "returns a failure", :aggregate_failures do
      expect(result).to be_failure
      expect(result.error).to eq("No notification supplied")
    end
  end

  context "with no product parameter" do
    let(:result) { described_class.call(user:, notification:) }

    it "returns a failure", :aggregate_failures do
      expect(result).to be_failure
      expect(result.error).to eq("No product supplied")
    end
  end

  context "with required parameters" do
    def expected_email_subject
      "Notification updated"
    end

    def expected_email_body(name)
      "Product was added to the notification by #{name}."
    end

    let(:result) { described_class.call(user:, notification:, product:) }

    it "returns success" do
      expect(result).to be_success
    end

    it "adds the product to the case" do
      result
      expect(notification.products).to include(product)
    end

    it "sets the product's owning team to be the user's team" do
      expect(result.product.owning_team).to eq(user.team)
    end

    it "creates an audit activity", :aggregate_failures do
      result
      activity = notification.reload.activities.first
      expect(activity).to be_a(AuditActivity::Product::Add)
      expect(activity.added_by_user).to eq(user)
      expect(activity.investigation_product).to eq(notification.investigation_products.first)
      expect(activity.title(nil)).to eq(product.name)
    end

    it_behaves_like "a service which notifies the notification owner"

    context "with a product owned by someone else" do
      let(:product) { create(:product, owning_team: create(:team)) }

      it "does not change the owning team", :aggregate_failures do
        expect(result.product.owning_team).not_to be_nil
        expect(result.product.owning_team).not_to eq(user.team)
      end
    end

    context "with a product that is already added to the case" do
      context "when an existing investigation_product exists but does not share the same investigation_closed_at" do
        before do
          notification.products << product
          notification.investigation_products.first.update!(investigation_closed_at: Time.current)
        end

        it "returns a success" do
          expect(result).to be_success
        end

        it "adds the product" do
          result
          expect(notification.investigation_products.count).to eq(2)
        end
      end

      context "when an existing investigation_product exists which shares the same investigation_closed_at" do
        before do
          notification.products << product
        end

        it "returns a failure", :aggregate_failures do
          expect(result).to be_failure
          expect(result.error).to eq("The product is already linked to the notification")
        end

        it "does not add the product twice" do
          result
          expect(notification.investigation_products.count).to eq(1)
        end
      end
    end
  end
end
