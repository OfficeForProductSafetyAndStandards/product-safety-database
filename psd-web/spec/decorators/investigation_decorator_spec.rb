require "rails_helper"

RSpec.describe InvestigationDecorator do
  fixtures(:investigations)

  let(:investigation) { investigations(:one) }

  subject { investigation.decorate }

  describe '#product_summary_list' do

    let(:product_summary_list) { Capybara.string(subject.product_summary_list) }

    it "has the expected fields" do
      expect(product_summary_list)
        .to have_css('dt.govuk-summary-list__key', text: "Product details")
      expect(product_summary_list)
        .to have_css('dd.govuk-summary-list__value', text: "2 products added")

      expect(product_summary_list)
        .to have_css('dt.govuk-summary-list__key', text: "Category")
      expect(product_summary_list)
        .to have_css('dd.govuk-summary-list__value', text: investigation.products.first.category)

      expect(product_summary_list)
        .to have_css('dt.govuk-summary-list__key', text: "Hazards")
      expect(product_summary_list)
        .to have_css('dd.govuk-summary-list__value', text: /#{investigation.hazard_type}/)
      expect(product_summary_list)
        .to have_css('dd.govuk-summary-list__value', text: /#{investigation.hazard_description}/)

      expect(product_summary_list)
        .to have_css('dt.govuk-summary-list__key', text: "Compliance")
      expect(product_summary_list)
        .to have_css('dd.govuk-summary-list__value', text: /#{investigation.non_compliant_reason}/)
    end

    context 'whithout products' do
      let(:investigation) { investigations(:no_products_case_title) }

      it { expect(subject.product_summary_list).to be_nil }
    end

    context 'whithout hazard_type' do
      before { investigation.hazard_type = nil }

      it { expect(product_summary_list).not_to have_css('dt.govuk-summary-list__key', text: "Hazards") }
    end

    context 'whithout non_compliant_reason' do
    end
  end
end
