require "rails_helper"

RSpec.describe ProductDecorator do
  fixtures(:products)

  let(:product) { products(:one) }

  subject { product.decorate }

  describe "#summary_list" do
    include CountriesHelper
    let(:summary_list) {
      subject.summary_list
    }

    context "when displaying the product summary" do
      it "displays the product summary list with the batch number" do
        expect(summary_list).to summarise("Product name",            text: product.name)
        expect(summary_list).to summarise("Category",                text: product.category)
        expect(summary_list).to summarise("Barcode or serial number", text: product.product_code)
        expect(summary_list).to summarise("Batch number",            text: product.batch_number)
        expect(summary_list).to summarise("Webpage",                 text: product.webpage)
        expect(summary_list).to summarise("Country of origin",       text: country_from_code(product.country_of_origin))
        expect(summary_list).to summarise("Description", text: product.description)
      end
    end
  end

  describe "#description" do
    include_examples "a formated text", :product, :description
  end
end
