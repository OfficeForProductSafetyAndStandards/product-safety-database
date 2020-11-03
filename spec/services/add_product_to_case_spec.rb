require "rails_helper"

RSpec.describe AddProductToCase, :with_stubbed_elasticsearch, :with_test_queue_adapter do
  let(:investigation) { create(:allegation, creator: creator) }
  let(:attributes) { attributes_for(:product_washing_machine) }

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
      let(:result) { described_class.call(user: user) }

      it "returns a failure", :aggregate_failures do
        expect(result).to be_failure
        expect(result.error).to eq("No investigation supplied")
      end
    end

    context "with no user parameter" do
      let(:result) { described_class.call(investigation: investigation) }

      it "returns a failure", :aggregate_failures do
        expect(result).to be_failure
        expect(result.error).to eq("No user supplied")
      end
    end

    context "with required parameters" do
      def expected_email_subject
        "Allegation updated"
      end

      def expected_email_body(name)
        "Product was added to the allegation by #{name}."
      end

      let(:result) { described_class.call(investigation: investigation, product: product, user: user, **attributes) }

      it "returns success" do
        expect(result).to be_success
      end

      it "adds the product to the case", :aggregate_failures do
        result.product

        expect(result.product).to have_attributes(attributes.except(:country_of_origin))
        expect(JSON(result.product.country_of_origin)).to eq(attributes[:country_of_origin])
        expect(result.product.investigation_products.where(investigation: investigation)).to exist
      end

      it "creates an audit activity", :aggregate_failures do
        result
        product = investigation.products.first
        activity = investigation.reload.activities.first
        expect(activity).to be_a(AuditActivity::Product::Add)
        expect(activity.source.user).to eq(user)
        expect(activity.product).to eq(product)
        expect(activity.title(nil)).to eq(product.name)
      end

      it_behaves_like "a service which notifies the case owner"
    end
  end
end
