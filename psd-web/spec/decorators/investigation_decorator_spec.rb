require "rails_helper"

RSpec.describe InvestigationDecorator, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper
  subject(:decorated_investigation) { investigation.decorate }

  let(:organisation) { create :organisation }
  let(:user)         { create(:user, organisation: organisation).decorate }
  let(:creator)      { create(:user, organisation: organisation) }
  let(:user_source)   { build(:user_source, user: creator) }
  let(:products)      { [] }
  let(:coronavirus_related) { false }
  let(:investigation) { create(:allegation, :reported_unsafe_and_non_compliant, coronavirus_related: coronavirus_related, products: products, assignable: user, source: user_source) }

  before { create(:complainant, investigation: investigation) }


  describe "#display_product_summary_list?" do
    let(:investigation) { create(:enquiry) }

    context "with no product" do
      it { is_expected.not_to be_display_product_summary_list }
    end

    context "with products" do
      before { investigation.products << create(:product) }

      it { is_expected.to be_display_product_summary_list }
    end
  end

  describe "#product_summary_list" do
    let(:product_summary_list) { decorated_investigation.product_summary_list }
    let(:products) { create_list(:product, 2) }

    it "displays the product details" do
      expect(product_summary_list).to summarise("Product details", text: "2 products added")
    end

    it "displays the categories" do
      investigation.products.each do |product|
        expect(product_summary_list).to summarise("Category", text: /#{Regexp.escape(product.category)}/i)
      end
    end

    it "displays the hazard type" do
      expect(product_summary_list).to summarise("Hazards", text: /#{Regexp.escape(investigation.hazard_type)}/)
    end

    it "displays the hazard description" do
      expect(product_summary_list).to summarise("Hazards", text: /#{Regexp.escape(investigation.hazard_description)}/)
    end

    it "displays the compliance reason" do
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
        expect(Capybara.string(product_summary_list))
          .to have_css("dd.govuk-summary-list__value p.govuk-body", text: random_product_category.upcase_first)
      end

      context "with two products on different categories" do
        let(:products_list) { [iphone, washing_machine] }

        it "displays the first product category" do
          expect(Capybara.string(product_summary_list))
            .to have_css("dd.govuk-summary-list__value ul.govuk-list li", text: iphone_3g.category.upcase_first)
        end

        it "displays the second product category" do
          expect(Capybara.string(product_summary_list))
            .to have_css("dd.govuk-summary-list__value ul.govuk-list li", text: iphone.category.upcase_first)
        end
      end
    end

    context "without hazard_type" do
      let(:product_summary_list) { Capybara.string(decorated_investigation.product_summary_list) }

      before do
        investigation.hazard_type = nil
        investigation.hazard_description = nil
      end

      it { expect(product_summary_list).not_to have_css("dt.govuk-summary-list__key", text: "Hazards") }
    end

    context "without non_compliant_reason" do
      let(:product_summary_list) { Capybara.string(decorated_investigation.product_summary_list) }

      before { investigation.non_compliant_reason = nil }

      it { expect(product_summary_list).not_to have_css("dt.govuk-summary-list__key", text: "Compliance") }
    end
  end

  describe "#pretty_description" do
    it {
      expect(decorated_investigation.pretty_description)
        .to eq("#{investigation.case_type.upcase_first}: #{investigation.pretty_id}")
    }
  end

  describe "#hazard_description" do
    include_examples "a formated text", :investigation, :hazard_description
  end

  describe "#investigation_summary_list" do
    let(:investigation_summary_list) { decorated_investigation.investigation_summary_list }

    it "displays the Status" do
      expect(investigation_summary_list).to summarise("Status", text: investigation.status)
    end

    it "displays the User name" do
      expect(investigation_summary_list).to summarise("Created by", text: /#{investigation.source.user.name}/)
    end

    it "displays the Team name" do
      expect(investigation_summary_list).to summarise("Created by", text: /#{investigation.source.user.team_names}/)
    end

    it "displays the Date created" do
      expect(investigation_summary_list).
        to summarise("Date created", text: investigation.created_at.to_s(:govuk))
    end

    it "displays the Last updated" do
      expect(investigation_summary_list).to summarise("Last updated", text: time_ago_in_words(investigation.updated_at))
    end

    it "displays the Trading Standards reference" do
      expect(investigation_summary_list).to summarise("Trading Standards reference", text: investigation.complainant_reference)
    end

    context "when the investigation is not coronavirus related" do
      let(:coronavirus_related) { false }

      it "displays the non-coronavirus related text" do
        expect(investigation_summary_list).to summarise("Coronavirus related", text: "Not a coronavirus related case")
      end
    end

    context "when the investigation is coronavirus related" do
      let(:coronavirus_related) { true }

      it "displays the coronavirus related text" do
        expect(investigation_summary_list).to summarise("Coronavirus related", text: "Coronavirus related case")
      end
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
      let(:investigation_summary_list) { Capybara.string(decorated_investigation.investigation_summary_list) }

      before { investigation.complainant_reference = nil }

      it { expect(investigation_summary_list).not_to have_css("dt.govuk-summary-list__key", text: "Trading Standards reference") }
    end
  end

  describe "#source_details_summary_list" do
    let(:source_details_summary_list) { decorated_investigation.source_details_summary_list }

    before do
      allow(User).to receive(:current).and_return(user)
    end

    it "does not display the Received date" do
      expect(source_details_summary_list).not_to summarise("Received date", text: investigation.date_received.to_s(:govuk))
    end

    it "does not display the Received by" do
      expect(source_details_summary_list).not_to summarise("Received by", text: investigation.received_type.upcase_first)
    end

    it "has displays the Source type" do
      expect(source_details_summary_list).to summarise("Source type", text: investigation.complainant.complainant_type)
    end

    it "has displays the Complainant name" do
      expect(source_details_summary_list).to summarise("Contact details", text: /#{Regexp.escape(investigation.complainant.name)}/)
    end

    it "has displays the Complainant phone number" do
      expect(source_details_summary_list).to summarise("Contact details", text: /#{Regexp.escape(investigation.complainant.phone_number)}/)
    end

    it "has displays the Complainant email address" do
      expect(source_details_summary_list).to summarise("Contact details", text: /#{Regexp.escape(investigation.complainant.email_address)}/)
    end

    it "has displays the Complainant other details" do
      expect(source_details_summary_list).to summarise("Contact details", text: /#{Regexp.escape(investigation.complainant.other_details)}/)
    end
  end

  describe "#non_compliant_reason" do
    include_examples "a formated text", :investigation, :non_compliant_reason
  end

  describe "#description" do
    include_examples "a formated text", :investigation, :description
  end

  describe "#products_list" do
    let(:products)           { create_list :product, product_count }
    let(:products_remaining) { investigation.products.count - described_class::PRODUCT_DISPLAY_LIMIT }
    let(:products_list)      { Capybara.string(decorated_investigation.products_list) }

    context "with 6 images or less" do
      let(:product_count) { 6 }

      it "lists all the images" do
        products.each do |product|
          expect(products_list).to have_link(product.name, href: product_path(product))
        end
      end

      it "does not display a link to see all attached images" do
        expect(products_list).not_to have_link("View #{products_remaining} more products...", href: investigation_products_path(investigation))
      end
    end

    context "with 7 images" do
      let(:product_count) { 7 }

      it "list all the products" do
        products.each do |product|
          expect(products_list).to have_link(product.name, href: product_path(product))
        end
      end

      it "does not display a link to see all the products" do
        expect(products_list).not_to have_link("View #{products_remaining} more products...", href: investigation_products_path(investigation))
      end
    end

    context "with more than 8 products" do
      let(:product_count) { 6 }
      let!(:products_not_to_display) { create_list :product, 2, investigations: [investigation] }

      it "lists the first page of products" do
        products.each do |product|
          expect(products_list).to have_link(product.name, href: product_path(product))
        end
      end

      it "does not display the products beyond the first page" do
        products_not_to_display.each do |product|
          expect(products_list).not_to have_link(product.name, href: product_path(product))
        end
      end

      it "displays a link to see all the products" do
        expect(products_list).to have_link("View #{products_remaining} more products...", href: investigation_products_path(investigation))
      end
    end
  end

  describe "#assignable_display_name_for" do
    let(:viewing_user) { build(:user) }

    context "when the investigation is assigned" do
      it "displays the assignee assignable name" do
        expect(decorated_investigation.assignable_display_name_for(viewing_user: viewing_user))
          .to eq(user.assignee_short_name(viewing_user: viewing_user))
      end
    end

    context "when the investigation is not assigned" do
      before { investigation.assignable = nil }

      it { expect(decorated_investigation.assignable_display_name_for(viewing_user: viewing_user)).to eq("Unassigned") }
    end
  end
end
