require "rails_helper"

RSpec.describe CreateProduct, :with_test_queue_adapter do
  let(:attributes) { attributes_for(:product_washing_machine) }

  describe ".call" do
    context "with required parameters" do
      let(:result) { described_class.call(**attributes) }

      it "returns success" do
        expect(result).to be_success
      end

      it "sets country_of_origin correctly", :aggregate_failures do
        result.product

        expect(result.product).to have_attributes(attributes.except(:country_of_origin))
        expect(JSON(result.product.country_of_origin)).to eq(attributes[:country_of_origin])
      end
    end
  end
end
