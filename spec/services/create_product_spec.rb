require "rails_helper"

RSpec.describe CreateProduct, :with_stubbed_opensearch, :with_test_queue_adapter do
  let(:attributes) { attributes_for(:product_washing_machine) }
  let(:user) { create(:user) }

  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      let(:result) { described_class.call }

      it "returns a failure", :aggregate_failures do
        expect(result).to be_failure
        expect(result.error).to eq("No user supplied")
      end
    end

    context "with required parameters" do
      let(:result) { described_class.call(user:, **attributes) }

      it "returns success" do
        expect(result).to be_success
      end

      it "sets country_of_origin correctly", :aggregate_failures do
        result.product

        expect(result.product).to have_attributes(attributes.except(:country_of_origin))
        expect(JSON(result.product.country_of_origin)).to eq(attributes[:country_of_origin])
      end

      it "sets the product's owning team to be the user's team" do
        expect(result.product.owning_team).to eq(user.team)
      end
    end
  end
end
