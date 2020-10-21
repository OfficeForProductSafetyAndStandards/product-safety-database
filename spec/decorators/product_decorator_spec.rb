require "rails_helper"

RSpec.describe ProductDecorator do
  subject(:decorated_product) { product.decorate }

  let(:product) { build(:product) }

  describe "#summary_list" do
    include CountriesHelper

    let(:summary_list) { decorated_product.summary_list }

    context "when displaying the product summary" do
      it "displays the Product name" do
        expect(summary_list).to summarise("Product name", text: product.name)
      end

      it "displays the Category" do
        expect(summary_list).to summarise("Category", text: product.category)
      end

      it "displays the Barcode" do
        expect(summary_list).to summarise("Barcode", text: product.gtin13)
      end

      it "displays the other product identifiers" do
        expect(summary_list).to summarise("Other product identifiers", text: product.product_code)
      end

      it "displays the Batch number" do
        expect(summary_list).to summarise("Batch number", text: product.batch_number)
      end

      it "displays the Webpage" do
        expect(summary_list).to summarise("Webpage", text: product.webpage)
      end

      it "displays the Country of origin" do
        expect(summary_list).to summarise("Country of origin", text: country_from_code(product.country_of_origin))
      end

      it "displays the Description" do
        expect(summary_list).to summarise("Description", text: product.description)
      end
    end
  end

  describe "#description" do
    include_examples "a formated text", :product, :description
  end

  describe "#product_type_and_category_label" do
    context "when both the product type and and category are present" do
      it "combines product type and product category" do
        expect(decorated_product.product_type_and_category_label)
          .to eq("#{product.product_type} (#{product.category.downcase})")
      end
    end

    context "when only the category is present" do
      before { product.product_type = nil }

      it "returns only the product category" do
        expect(decorated_product.product_type_and_category_label)
          .to eq(product.category)
      end
    end

    context "when only the product type is present" do
      before { product.category = nil }

      it "returns only the product type" do
        expect(decorated_product.product_type_and_category_label)
          .to eq(product.product_type)
      end
    end
  end
end
