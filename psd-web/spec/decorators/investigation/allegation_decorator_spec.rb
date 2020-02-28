require "rails_helper"

RSpec.describe Investigation::AllegationDecorator do
  fixtures(:investigation_products, :investigations, :products)

  subject(:decorated_allegation) { allegation.decorate }

  let(:allegation) { investigations :one_product }


  describe "#display_product_summary_list?" do
    it { is_expected.to be_display_product_summary_list }
  end

  describe "#title" do
    context "when products are present" do
      context "with one product" do
        it "produces the correct title" do
          expect(allegation.decorate.title).to eq("iPhone XS MAX, phone – asphyxiation hazard")
        end
      end

      context "with two products" do
        context "with two common values" do
          let!(:allegation) { investigations :two_products_with_common_values }

          it "produces the correct title" do
            expect(allegation.decorate.title).to eq("2 products, phone – asphyxiation hazard")
          end
        end

        context "with no common values" do
          let!(:allegation) { investigations :two_products_with_no_common_values }

          it "produces the correct title" do
            expect(allegation.decorate.title).to eq("2 products – asphyxiation hazard")
          end
        end
      end
    end

    context "when no products are present on the case" do
      let(:allegation) { investigations :no_products_case_title }

      it "has the correct title" do
        expect(decorated_allegation.title).to eq("Alarms – asphyxiation hazard (no product specified)")
      end
    end
  end
end
