require "rails_helper"

RSpec.describe InvestigationDecorator, :with_stubbed_mailer do
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper
  subject(:decorated_investigation) { investigation.decorate }

  let(:organisation)  { create :organisation }
  let(:user)          { create(:user, organisation:).decorate }
  let(:team)          { create(:team) }
  let(:creator)       { create(:user, :opss_user, organisation:, team:) }
  let(:products)      { [] }
  let(:risk_level)    { :serious }
  let(:coronavirus_related) { false }
  let(:investigation) do
    create(:allegation,
           :reported_unsafe_and_non_compliant,
           products:,
           coronavirus_related:,
           creator:,
           risk_level:)
  end

  before do
    ChangeCaseOwner.call!(investigation:, user: creator, owner: user)
    create(:complainant, investigation:)
  end

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

  describe "#risk_level_description" do
    let(:risk_level_description) { decorated_investigation.risk_level_description }

    context "when the risk level is set" do
      let(:investigation) { create(:allegation, risk_level: :high) }

      it "displays the risk level text corresponding to the risk level" do
        expect(risk_level_description).to eq "High risk"
      end
    end

    context "when the risk level is set to other" do
      let(:investigation) { create(:allegation, risk_level: "other", custom_risk_level: "Custom risk") }

      it "displays the custom risk level" do
        expect(risk_level_description).to eq "Custom risk"
      end
    end

    context "when the risk level and the custom risk level are not set" do
      let(:investigation) { create(:allegation, risk_level: nil, custom_risk_level: nil) }

      it "displays 'Not set'" do
        expect(risk_level_description).to eq "Not set"
      end
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
  end

  describe "#pretty_description" do
    it {
      expect(decorated_investigation.pretty_description)
        .to eq("Case: #{investigation.pretty_id}")
    }
  end

  describe "#source_details_summary_list" do
    let(:view_protected_details) { true }
    let(:source_details_summary_list) { decorated_investigation.source_details_summary_list(view_protected_details:) }

    it "does not display the Received date" do
      expect(source_details_summary_list).not_to summarise("Received date", text: investigation.date_received.to_formatted_s(:govuk))
    end

    it "does not display the Received by" do
      expect(source_details_summary_list).not_to summarise("Received by", text: investigation.received_type.upcase_first)
    end

    it "displays the Source type" do
      expect(source_details_summary_list).to summarise("Source type", text: investigation.complainant.complainant_type)
    end

    context "when view_protected_details is true" do
      let(:view_protected_details) { true }

      it "displays the complainant details", :aggregate_failures do
        expect_to_display_protect_details_message
        expect(source_details_summary_list).to summarise("Contact details", text: /#{Regexp.escape(investigation.complainant.name)}/)
        expect(source_details_summary_list).to summarise("Contact details", text: /#{Regexp.escape(investigation.complainant.phone_number)}/)
        expect(source_details_summary_list).to summarise("Contact details", text: /#{Regexp.escape(investigation.complainant.email_address)}/)
        expect(source_details_summary_list).to summarise("Contact details", text: /#{Regexp.escape(investigation.complainant.other_details)}/)
      end
    end

    context "when view_protected_details is false" do
      let(:view_protected_details) { false }

      it "does not display the Complainant details", :aggregate_failures do
        expect_to_display_protect_details_message
        expect(source_details_summary_list).not_to summarise("Contact details", text: /#{Regexp.escape(investigation.complainant.name)}/)
        expect(source_details_summary_list).not_to summarise("Contact details", text: /#{Regexp.escape(investigation.complainant.phone_number)}/)
        expect(source_details_summary_list).not_to summarise("Contact details", text: /#{Regexp.escape(investigation.complainant.email_address)}/)
        expect(source_details_summary_list).not_to summarise("Contact details", text: /#{Regexp.escape(investigation.complainant.other_details)}/)
      end
    end

    def expect_to_display_protect_details_message
      expect(source_details_summary_list).to summarise("Contact details", text: /Only teams added to the case can view allegation contact details/)
    end
  end

  describe "#description" do
    include_examples "a formated text", :investigation, :description
    include_examples "with a blank description", :investigation, :decorated_investigation
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

  describe "#owner_display_name_for" do
    let(:viewer) { build(:user) }

    it "displays the owner name" do
      expect(decorated_investigation.owner_display_name_for(viewer:))
        .to eq(user.owner_short_name(viewer:))
    end
  end

  describe "#generic_attachment_partial" do
    let(:partial) { decorated_investigation.generic_attachment_partial(viewing_user) }

    context "when the viewer has accees to view the restricted details" do
      let(:viewing_user) { investigation.owner }

      it { expect(partial).to eq("documents/generic_document_card") }
    end

    context "when the viewer does not has accees to view the restricted details" do
      let(:viewing_user) { create(:user) }

      it { expect(partial).to eq("documents/restricted_generic_document_card") }
    end
  end

  describe "#title" do
    context "with a user_title" do
      let(:user_title) { "user title" }
      let(:investigation) { create(:case, user_title:, complainant_reference: nil) }

      it { expect(decorated_investigation.title).to eq(user_title) }
    end

    context "without a user_title but with a complainant_reference" do
      let(:complainant_reference) { "complainant reference" }
      let(:investigation) { create(:case, user_title: nil, complainant_reference:) }

      it { expect(decorated_investigation.title).to eq(complainant_reference) }
    end

    context "without a user_title or a complainant_reference" do
      let(:investigation) { create(:case, user_title: nil, complainant_reference: nil) }

      it "uses the pretty_id" do
        expect(decorated_investigation.title).to eq(investigation.pretty_id)
      end
    end
  end

  describe "#case_title_key" do
    let(:viewing_user) { create(:user) }
    let(:case_title_key) { decorated_investigation.case_title_key(viewing_user) }
    let(:user_title)     { "user title" }

    context "with unrestricted case" do
      let(:investigation) { create(:allegation, user_title:) }

      it { expect(case_title_key).to include(user_title) }
    end

    context "with restricted case" do
      let(:investigation) { create(:allegation, user_title:, is_private: true) }

      it { expect(case_title_key).to eq("Case restricted") }
    end

    context "with restricted case as a super user" do
      let(:investigation) { create(:allegation, user_title:, is_private: true) }
      let(:viewing_user) { create(:user, :super_user) }

      it { expect(case_title_key).to include("Case restricted - user title") }
    end
  end

  describe "#case_summary_values" do
    let(:case_summary_values) { decorated_investigation.case_summary_values }
    let(:text_values) { case_summary_values.pluck(:text).compact }
    let(:html_value) { case_summary_values.pluck(:html).compact.join }

    context "with unrestricted case" do
      let(:investigation) { create(:allegation, is_closed: true) }

      it { expect(text_values).to include(investigation.pretty_id) }
      it { expect(text_values).to include(investigation.owner_team.name) }
      it { expect(html_value).to include("Closed") }
    end

    context "with restricted case" do
      let(:investigation) { create(:allegation, is_private: true, is_closed: false) }

      it { expect(text_values).not_to include(investigation.pretty_id) }
      it { expect(text_values).not_to include(investigation.owner_team.name) }
      it { expect(html_value).to include("Open") }
    end
  end
end
