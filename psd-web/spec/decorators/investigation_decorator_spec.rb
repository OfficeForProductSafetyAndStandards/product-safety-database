require "rails_helper"

RSpec.describe InvestigationDecorator do
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper

  fixtures(:investigations, :investigation_products, :products)

  let(:investigation) { investigations(:one) }

  subject { investigation.decorate }

  describe "#display_product_summary_list?" do
    let(:investigation) { investigations(:enquiry) }
    context "with no product" do
      it { is_expected.to_not be_display_product_summary_list }
    end

    context "with products" do
      before { investigation.products << products(:one) }

      it { is_expected.to be_display_product_summary_list }
    end
  end

  describe "#product_summary_list" do
    let(:product_summary_list) { subject.product_summary_list }

    it "has the expected fields" do
      expect(product_summary_list).to summarise("Product details", text: "2 products added")
      expect(product_summary_list).to summarise("Category", text: investigation.products.first.category)
      expect(product_summary_list).to summarise("Hazards", text: /#{investigation.hazard_type}/)
      expect(product_summary_list).to summarise("Hazards", text: /#{investigation.hazard_description}/)
      expect(product_summary_list).to summarise("Compliance", text: /#{investigation.non_compliant_reason}/)
    end

    context "with two products of the same category" do
      fixtures(:products)
      let(:iphone_3g)     { products(:iphone_3g) }
      let(:iphone)        { products(:iphone)  }
      let(:samsung)       { products(:samsung) }
      let(:products_list) { [iphone_3g, samsung] }

      before do
        investigation.assign_attributes(
          product_category: iphone_3g.category,
          products: products_list
        )
      end

      it "displays the only category present a paragraphe" do
        random_product_category = investigation.products.sample.category
        expect(product_summary_list)
          .to have_css("dd.govuk-summary-list__value p.govuk-body", text: random_product_category.upcase_first)
      end

      context "with two products on different categories" do
        let(:products_list) { [iphone, iphone_3g] }

        it "displays a categories as a list" do
          expect(product_summary_list)
            .to have_css("dd.govuk-summary-list__value ul.govuk-list li", text: iphone_3g.category.upcase_first)
          expect(product_summary_list)
            .to have_css("dd.govuk-summary-list__value ul.govuk-list li", text: iphone.category.upcase_first)
        end
      end
    end

    context "whithout hazard_type" do
      let(:product_summary_list) { Capybara.string(subject.product_summary_list) }

      before do
        investigation.hazard_type = nil
        investigation.hazard_description = nil
      end

      it { expect(product_summary_list).not_to have_css("dt.govuk-summary-list__key", text: "Hazards") }
    end

    context "whithout non_compliant_reason" do
      let(:product_summary_list) { Capybara.string(subject.product_summary_list) }

      before { investigation.non_compliant_reason = nil }

      it { expect(product_summary_list).not_to have_css("dt.govuk-summary-list__key", text: "Compliance") }
    end
  end

  describe "#investigation_summary_list" do
    fixtures(:sources)
    let(:investigation_summary_list) { subject.investigation_summary_list }
    let(:expected_creator_name)      { investigation.source.show }

    it "has the expected fields" do
      expect(investigation_summary_list).to summarise("Status", text: investigation.status)
      expect(investigation_summary_list).to summarise("Created by", text: expected_creator_name)
      expect(investigation_summary_list).to summarise("Assigned to", text: /Unassigned/)
      expect(investigation_summary_list).
        to summarise("Date created", text: investigation.created_at.beginning_of_month.strftime("%e %B %Y"))
      expect(investigation_summary_list).to summarise("Last updated", text: time_ago_in_words(investigation.updated_at))
      expect(investigation_summary_list).to summarise("Trading Standards reference", text: investigation.complainant_reference)
    end

    context "when investigation has no source" do
      before { investigation.source = nil }

      it "renders nothing as the Created by" do
        expect(investigation_summary_list).to summarise("Created by", text: "")
      end
    end

    context "when the investigation's source no user" do
      before { investigation.source.user = nil }

      it "renders nothing as the Created by" do
        expect(investigation_summary_list).to summarise("Created by", text: "")
      end
    end

    context "without complainant reference" do
      let(:investigation_summary_list) { Capybara.string(subject.investigation_summary_list) }

      before { investigation.complainant_reference = nil }

      it { expect(investigation_summary_list).not_to have_css("dt.govuk-summary-list__key", text: "Trading Standards reference") }
    end
  end

  describe "#source_details_summary_list" do
    fixtures(:complainants, :sources, :organisations, :users)
    let(:investigation) { investigations(:enquiry) }
    let(:source_details_summary_list) { subject.source_details_summary_list }

    before do
      User.current = users(:opss)
      investigation.source = sources(:investigation_one)
      investigation.complainant = complainants(:one)
    end

    it "has the expected fields" do
      expect(source_details_summary_list).to summarise("Received date",   text: investigation.date_received.strftime("%e %B %Y"))
      expect(source_details_summary_list).to summarise("Received by",     text: investigation.received_type.upcase_first)
      expect(source_details_summary_list).to summarise("Source type",     text: investigation.complainant.complainant_type)
      expect(source_details_summary_list).to summarise("Contact details", text: /#{investigation.complainant.name}/)
      expect(source_details_summary_list).to summarise("Contact details", text: /#{investigation.complainant.phone_number}/)
      expect(source_details_summary_list).to summarise("Contact details", text: /#{investigation.complainant.email_address}/)
      expect(source_details_summary_list).to summarise("Contact details", text: /#{investigation.complainant.other_details}/)
    end
  end

  describe '#pretty_description' do
    it { expect(subject.pretty_description)
        .to eq("#{investigation.case_type.titleize}: #{investigation.pretty_id}") }
  end
end
