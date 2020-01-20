require "rails_helper"

RSpec.describe InvestigationDecorator, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper
  let(:organisation) { create :organisation }
  let(:user)         { create(:user, organisation: organisation) }
  let(:creator)      { create(:user, organisation: organisation) }
  let(:user_source)   { build(:user_source, user: creator) }
  let(:products)      { [] }
  let(:investigation) { create(:allegation, products: products, assignee: user, source: user_source) }
  let!(:complainant) { create(:complainant, investigation: investigation) }

  subject { investigation.decorate }

  describe "#display_product_summary_list?" do
    let(:investigation) { create(:enquiry) }

    context "with no product" do
      it { is_expected.to_not be_display_product_summary_list }
    end

    context "with products" do
      before { investigation.products << create(:product) }

      it { is_expected.to be_display_product_summary_list }
    end
  end

  describe "#product_summary_list" do
    let(:product_summary_list) { subject.product_summary_list }
    let(:products) { create_list(:product, 2) }

    it "has the expected fields" do
      expect(product_summary_list).to summarise("Product details", text: "2 products added")
      investigation.products.each do |product|
        expect(product_summary_list).to summarise("Category", text: /#{Regexp.escape(product.category)}/i)
      end

      expect(product_summary_list).to summarise("Hazards", text: /#{Regexp.escape(investigation.hazard_type)}/)
      expect(product_summary_list).to summarise("Hazards", text: /#{Regexp.escape(investigation.hazard_description)}/)
      expect(product_summary_list).to summarise("Compliance", text: /#{Regexp.escape(investigation.non_compliant_reason)}/)
    end

    context "with two products of the same category" do
      let(:washing_machine) { build(:product_washing_machine) }
      let(:iphone_3g)       { build(:product_iphone_3g) }
      let(:iphone)          { build(:product_iphone)  }
      let(:samsung)         { build(:product_samsung) }
      let(:products_list)   { [iphone_3g, samsung] }

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
        let(:products_list) { [iphone, washing_machine] }

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
    include Investigations::DisplayTextHelper

    let(:investigation_summary_list) { subject.investigation_summary_list }

    it "has the expected fields" do
      expect(investigation_summary_list).to summarise("Status", text: investigation.status)
      expect(investigation_summary_list).to summarise("Created by", text: /#{Regexp.escape(investigation.source.user.name)}/)
      expect(investigation_summary_list).to summarise("Created by", text: /#{Regexp.escape(investigation.source.user.organisation.name)}/)
      expect(investigation_summary_list).to summarise("Assigned to", text: /#{Regexp.escape(user.name.to_s)}/)
      expect(investigation_summary_list).
        to summarise("Date created", text: investigation.created_at.to_s(:govuk))
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
    let(:source_details_summary_list) { subject.source_details_summary_list }

    before { allow(User).to receive(:current).and_return(user) }

    it "has the expected fields" do
      expect(source_details_summary_list).to summarise("Received date",   text: investigation.date_received.to_s(:govuk))
      expect(source_details_summary_list).to summarise("Received by",     text: investigation.received_type.upcase_first)
      expect(source_details_summary_list).to summarise("Source type",     text: investigation.complainant.complainant_type)
      expect(source_details_summary_list).to summarise("Contact details", text: /#{Regexp.escape(investigation.complainant.name)}/)
      expect(source_details_summary_list).to summarise("Contact details", text: /#{Regexp.escape(investigation.complainant.phone_number)}/)
      expect(source_details_summary_list).to summarise("Contact details", text: /#{Regexp.escape(investigation.complainant.email_address)}/)
      expect(source_details_summary_list).to summarise("Contact details", text: /#{Regexp.escape(investigation.complainant.other_details)}/)
    end
  end

  describe "#pretty_description" do
    it {
      expect(subject.pretty_description)
        .to eq("#{investigation.case_type.titleize}: #{investigation.pretty_id}")
    }
  end

  describe "#hazard_descrition" do
    include_examples "a formated text", :investigation, :hazard_description
  end

  describe "#product_summary_list" do
    let(:products) { create_list :product, 2 }
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
    let(:investigation_summary_list) { subject.investigation_summary_list }

    it "has the expected fields" do
      expect(investigation_summary_list).to summarise("Status", text: investigation.status)
      expect(investigation_summary_list).to summarise("Created by", text: /#{investigation.source.user.name}/)
      expect(investigation_summary_list).to summarise("Created by", text: /#{investigation.source.user.organisation.name}/)
      expect(investigation_summary_list).to summarise("Assigned to", text: /#{Regexp.escape(user.name.to_s)}/)
      expect(investigation_summary_list).
        to summarise("Date created", text: investigation.created_at.to_s(:govuk))
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
    let(:source_details_summary_list) { subject.source_details_summary_list }

    before do
      allow(User).to receive(:current).and_return(user)
    end

    it "has the expected fields" do
      expect(source_details_summary_list).to summarise("Received date",   text: investigation.date_received.to_s(:govuk))
      expect(source_details_summary_list).to summarise("Received by",     text: investigation.received_type.upcase_first)
      expect(source_details_summary_list).to summarise("Source type",     text: investigation.complainant.complainant_type)
      expect(source_details_summary_list).to summarise("Contact details", text: /#{Regexp.escape(investigation.complainant.name)}/)
      expect(source_details_summary_list).to summarise("Contact details", text: /#{Regexp.escape(investigation.complainant.phone_number)}/)
      expect(source_details_summary_list).to summarise("Contact details", text: /#{Regexp.escape(investigation.complainant.email_address)}/)
      expect(source_details_summary_list).to summarise("Contact details", text: /#{Regexp.escape(investigation.complainant.other_details)}/)
    end
  end

  describe "#non_compliant_reason" do
    include_examples "a formated text", :investigation, :non_compliant_reason
  end

  describe "#pretty_description" do
    it {
      expect(subject.pretty_description)
        .to eq("#{investigation.case_type.titleize}: #{investigation.pretty_id}")
    }
  end

  describe "#description" do
    include_examples "a formated text", :investigation, :description
  end

  describe "#products_list" do
    let(:products)           { create_list :product, product_count }
    let(:products_remaining) { investigation.products.count - described_class::PRODUCT_IMAGE_DISPLAY_LIMIT }
    let(:products_list)      { Capybara.string(subject.products_list) }

    context "with 6 images or less" do
      let(:product_count) { 6 }

      it "lists all the images" do
        products.each do |product|
          expect(products_list).to have_link(product.name, href: product_path(product))
        end
      end

      it "does not displays a link to see all attached images" do
        expect(products_list).to_not have_link("View #{products_remaining} more products...", href: investigation_products_path(investigation))
      end
    end

    context "with 7 images" do
      let(:product_count) { 7 }

      it "list all the products" do
        products.each do |product|
          expect(products_list).to have_link(product.name, href: product_path(product))
        end
      end

      it "does not displays a link to see all the products" do
        expect(products_list).to_not have_link("View #{products_remaining} more products...", href: investigation_products_path(investigation))
      end
    end

    context "with more than 8 products" do
      let(:product_count) { 6 }
      let!(:products_not_to_display) { create_list :product, 2, investigations: [investigation] }

      it "lists the first 6 products" do
        products.each do |product|
          expect(products_list).to have_link(product.name, href: product_path(product))
        end
        products_not_to_display.each do |product|
          expect(products_list).to_not have_link(product.name, href: product_path(product))
        end
      end

      it "displays a link to see all the products" do
        expect(products_list).to have_link("View #{products_remaining} more products...", href: investigation_products_path(investigation))
      end
    end
  end

end
