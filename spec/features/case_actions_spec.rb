require "rails_helper"

RSpec.feature "Case actions", :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create :user, :opss_user, :activated, has_viewed_introduction: true }
  let(:washing_machine) { create :product_washing_machine }
  let(:investigation_a) { create :allegation, creator: user }
  let(:investigation_b) { create :allegation, products: [washing_machine], creator: user }
  let(:investigation_c) { create :allegation, read_only_teams: [user.team] }
  let(:investigation_d) { create :allegation, :with_business, :with_products, :with_document, creator: user }
  let(:investigation_e) { create :allegation, :with_business, :with_products, :with_document, creator: user, is_closed: true, date_closed: Date.new(2021, 1, 1) }

  context "when a super user" do
    let(:super_user) { create(:user, :super_user, :activated, has_viewed_introduction: true) }

    before do
      sign_in super_user
    end

    scenario "with a closed case as a super user" do
      visit investigation_path(investigation_e)
      expect_to_be_on_case_page(case_id: investigation_e.pretty_id)

      within("#page-content section dl.govuk-summary-list") do
        expect(page).to have_text("Product (1 added)")
        expect(page).to have_text("Business (1 added)")
        expect(page).to have_text("Notification image (0 added)")
        expect(page).to have_text("Accident / Incident (0 added)")
        expect(page).to have_text("Corrective action (0 added)")
        expect(page).to have_text("Risk assessment (0 added)")
        expect(page).to have_text("Correspondence (0 added)")
        expect(page).to have_text("Test result (0 added)")
        expect(page).to have_text("Other supporting information (1 added)")
      end
    end
  end

  context "when an opss user" do
    before do
      sign_in user
    end

    scenario "without a product added to the case" do
      visit investigation_path(investigation_a)
      expect_to_be_on_case_page(case_id: investigation_a.pretty_id)
      expect(page).to have_css(".govuk-warning-text")
      expect(page).to have_text("A product has not been added to this notification.")

      within("#page-content section dl.govuk-summary-list") do
        expect(page).to have_text("Product (0 added)")
        expect(page).to have_text("Business (0 added)")
        expect(page).to have_text("Notification image (0 added)")
        expect(page).to have_text("Accident / Incident (0 added)")
        expect(page).to have_text("Corrective action (0 added)")
        expect(page).to have_text("Risk assessment (0 added)")
        expect(page).to have_text("Correspondence (0 added)")
        expect(page).to have_text("Test result (0 added)")
        expect(page).to have_text("Other supporting information (0 added)")
      end
    end

    scenario "with a product added to the case" do
      visit investigation_path(investigation_b)
      expect_to_be_on_case_page(case_id: investigation_b.pretty_id)
      expect(page).not_to have_css(".govuk-warning-text")

      within("#page-content section dl.govuk-summary-list") do
        expect(page).to have_text("Product (1 added)")
        expect(page).to have_text("Business (0 added)")
        expect(page).to have_text("Notification image (0 added)")
        expect(page).to have_text("Accident / Incident (0 added)")
        expect(page).to have_text("Corrective action (0 added)")
        expect(page).to have_text("Risk assessment (0 added)")
        expect(page).to have_text("Correspondence (0 added)")
        expect(page).to have_text("Test result (0 added)")
        expect(page).to have_text("Other supporting information (0 added)")
      end
    end

    scenario "where the user can edit the case" do
      visit investigation_path(investigation_a)
      within("#page-content section dl.govuk-summary-list") do
        expect(page).to have_link("Add a product", href: new_investigation_product_path(investigation_a))
        expect(page).to have_link("Add a business", href: new_investigation_business_types_path(investigation_a))
        expect(page).to have_link("Add a notification image", href: new_investigation_image_upload_path(investigation_a))
        expect(page).to have_link("Add an accident or incident", href: new_investigation_accident_or_incidents_type_path(investigation_a))
        expect(page).to have_link("Add a corrective action", href: new_investigation_corrective_action_path(investigation_a))
        expect(page).to have_link("Add a prism risk assessment", href: new_investigation_prism_risk_assessment_path(investigation_a))
        expect(page).to have_link("Add a correspondence", href: new_investigation_correspondence_path(investigation_a))
        expect(page).to have_link("Add a test result", href: new_investigation_funding_source_path(investigation_a))
        expect(page).to have_link("Add a document or attachment", href: new_investigation_document_path(investigation_a))
        expect(page).to have_link("Add a comment", href: new_investigation_activity_comment_path(investigation_a))
      end
    end

    scenario "where the user can not edit the case" do
      visit investigation_path(investigation_c)
      within("#page-content section dl.govuk-summary-list") do
        expect(page).not_to have_link("Add a product")
        expect(page).not_to have_link("Add a business")
        expect(page).not_to have_link("Add an image")
        expect(page).not_to have_link("Add an accident or incident")
        expect(page).not_to have_link("Add a corrective action")
        expect(page).not_to have_link("Add a risk assessment")
        expect(page).not_to have_link("Add a correspondence")
        expect(page).not_to have_link("Add a test result")
        expect(page).not_to have_link("Add a document or attachment")
        expect(page).to have_link("Add a comment", href: new_investigation_activity_comment_path(investigation_c))
      end
    end

    scenario "with some information added to the case" do
      visit investigation_path(investigation_d)
      within("#page-content section dl.govuk-summary-list") do
        expect(page).to have_text("Product (1 added)")
        expect(page).to have_text("Business (1 added)")
        expect(page).to have_text("Notification image (0 added)")
        expect(page).to have_text("Accident / Incident (0 added)")
        expect(page).to have_text("Corrective action (0 added)")
        expect(page).to have_text("Risk assessment (0 added)")
        expect(page).to have_text("Correspondence (0 added)")
        expect(page).to have_text("Test result (0 added)")
        expect(page).to have_text("Other supporting information (1 added)")
      end
    end
  end
end
