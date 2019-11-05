require "rails_helper"

RSpec.describe Investigation::AllegationDecorator do
  fixtures(:investigations)
  let!(:allegation) { investigations(:one) }

  subject { allegation.decorate }

  describe "#title" do
    context "when products are present" do
      context "with one product" do
        let(:allegation) { investigations :one_product }

        it "produces the correct title" do
          expect(subject.title).to eq("iPhone XS MAX, phone – Asphyxiation")
        end
      end
      context "with two produtcs" do
        context "with two common values" do
          let(:allegation) { investigations :two_products_with_common_values }

          it "produces the correct title" do
            expect(subject.title).to eq("2 Products, phone – Asphyxiation")
          end
        end

        context "with no common values" do
          let(:allegation) { investigations :two_products_with_no_common_values }

          it "produces the correct title" do
            expect(subject.title).to eq("2 Products – Asphyxiation")
          end
        end
      end
    end

    context "when no products are present on the case" do
      let(:allegation) { investigations :no_products_case_title }

      it "has the corect title" do
        expect(subject.title).to eq("Alarms – Asphyxiation (no product specified)")
      end
    end
  end
end
