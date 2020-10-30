require "rails_helper"

RSpec.describe RemoveProductFromCase, :with_stubbed_elasticsearch, :with_test_queue_adapter do
  let(:investigation) { create(:allegation, products: [product], creator: creator) }
  let(:product) { create(:product_washing_machine) }

  let(:user) { create(:user) }
  let(:creator) { user }
  let(:owner) { user }

  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no investigation parameter" do
      let(:result) { described_class.call(product: product, user: user) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no product parameter" do
      let(:result) { described_class.call(investigation: investigation, user: user) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      let(:result) { described_class.call(investigation: investigation, product: product) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with required parameters" do
      def expected_email_subject
        "Allegation updated"
      end

      def expected_email_body(name)
        "Product was removed from the allegation by #{name}."
      end

      let(:result) { described_class.call(investigation: investigation, product: product, user: user) }

      it "returns success" do
        expect(result).to be_success
      end

      it "removes the product from the case" do
        result
        expect(investigation.reload.products).not_to include(product)
      end

      it "creates an audit activity", :aggregate_failures do
        result
        activity = investigation.reload.activities.first
        expect(activity).to be_a(AuditActivity::Product::Destroy)
        expect(activity.source.user).to eq(user)
        expect(activity.product).to eq(product)
        expect(activity.title(nil)).to eq("Removed: #{product.name}")
      end

      it_behaves_like "a service which notifies the case owner"
    end
  end
end
