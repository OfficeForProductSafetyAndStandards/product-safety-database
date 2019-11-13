require "rails_helper"

RSpec.describe InvestigationDecorator do
  fixtures(:investigations, :investigation_products, :products)

  let(:investigation) { investigations(:one) }

  subject { investigation.decorate }

  describe '#product_summary_list' do

    let(:product_summary_list) { subject.product_summary_list }

    it "has the expected fields" do
      expect(product_summary_list).to summarise("Product details", text: "2 products added")
      expect(product_summary_list).to summarise("Category", text: investigation.products.first.category)
      expect(product_summary_list).to summarise("Hazards", text: /#{investigation.hazard_type}/)
      expect(product_summary_list).to summarise("Hazards", text: /#{investigation.hazard_description}/)
      expect(product_summary_list).to summarise("Compliance", text: /#{investigation.non_compliant_reason}/)
    end

    context 'whithout products' do
      let(:investigation) { investigations(:no_products_case_title) }

      it { expect(subject.product_summary_list).to be_nil }
    end

    context 'whithout hazard_type' do
      let(:product_summary_list) { Capybara.string(subject.product_summary_list) }

      before do
        investigation.hazard_type = nil
        investigation.hazard_description = nil
      end

      it { expect(product_summary_list).not_to have_css('dt.govuk-summary-list__key', text: "Hazards") }
    end

    context 'whithout non_compliant_reason' do
      let(:product_summary_list) { Capybara.string(subject.product_summary_list) }

      before { investigation.non_compliant_reason = nil }

      it { expect(product_summary_list).not_to have_css('dt.govuk-summary-list__key', text: "Compliance") }
    end
  end
end
