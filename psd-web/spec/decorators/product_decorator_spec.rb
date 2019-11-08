require "rails_helper"

RSpec.describe ProductDecorator do
  fixtures(:products)

  let(:product) { products(:one) }

  subject { product.decorate }

  describe "#summary_list" do
    include CountriesHelper
    let(:summary_list) do
      Capybara.string(subject.summary_list(include_batch_number: include_batch_number))
    end

    context "when including the batch number" do
      let(:include_batch_number) { true }

      it "displays the product summary list with the batch number" do
        expect(summary_list).to have_css("dl dt.govuk-summary-list__key",   text: "Product name")
        expect(summary_list).to have_css("dl dd.govuk-summary-list__value", text: product.name)

        expect(summary_list).to have_css("dl dt.govuk-summary-list__key",   text: "Barcode / serial number")
        expect(summary_list).to have_css("dl dd.govuk-summary-list__value", text: product.product_code)

        expect(summary_list).to have_css("dl dt.govuk-summary-list__key",   text: "Batch number")
        expect(summary_list).to have_css("dl dd.govuk-summary-list__value", text: product.batch_number)

        expect(summary_list).to have_css("dl dt.govuk-summary-list__key",   text: "Category")
        expect(summary_list).to have_css("dl dd.govuk-summary-list__value", text: product.category)

        expect(summary_list).to have_css("dl dt.govuk-summary-list__key",   text: "Webpage")
        expect(summary_list).to have_css("dl dd.govuk-summary-list__value", text: product.webpage)

        expect(summary_list).to have_css("dl dt.govuk-summary-list__key",   text: "Country of origin")
        expect(summary_list).to have_css("dl dd.govuk-summary-list__value", text: country_from_code(product.country_of_origin))

        expect(summary_list).to have_css("dl dt.govuk-summary-list__key",   text: "Description")
        expect(summary_list).to have_css("dl dd.govuk-summary-list__value", text: product.description)
      end
    end

    context "when not including the batch number" do
      let(:include_batch_number) { false }

      it "displays the summary list without the batch number" do
        expect(summary_list).to have_css("dl dt.govuk-summary-list__key",   text: "Product name")
        expect(summary_list).to have_css("dl dd.govuk-summary-list__value", text: product.name)

        expect(summary_list).to have_css("dl dt.govuk-summary-list__key",   text: "Barcode / serial number")
        expect(summary_list).to have_css("dl dd.govuk-summary-list__value", text: product.product_code)

        expect(summary_list).to_not have_css("dl dt.govuk-summary-list__key",   text: "Batch number")
        expect(summary_list).to_not have_css("dl dd.govuk-summary-list__value", text: product.batch_number)

        expect(summary_list).to have_css("dl dt.govuk-summary-list__key",   text: "Category")
        expect(summary_list).to have_css("dl dd.govuk-summary-list__value", text: product.category)

        expect(summary_list).to have_css("dl dt.govuk-summary-list__key",   text: "Webpage")
        expect(summary_list).to have_css("dl dd.govuk-summary-list__value", text: product.webpage)

        expect(summary_list).to have_css("dl dt.govuk-summary-list__key",   text: "Country of origin")
        expect(summary_list).to have_css("dl dd.govuk-summary-list__value", text: country_from_code(product.country_of_origin))

        expect(summary_list).to have_css("dl dt.govuk-summary-list__key",   text: "Description")
        expect(summary_list).to have_css("dl dd.govuk-summary-list__value", text: product.description)
      end
    end
  end
end
