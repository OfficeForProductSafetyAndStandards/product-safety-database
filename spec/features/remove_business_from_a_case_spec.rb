require "rails_helper"

RSpec.feature "Remove a business from a case", :with_stubbed_mailer do
  let(:business)      { create(:business) }
  let(:user)          { create(:user, :activated, has_accepted_declaration: true) }
  let(:investigation) { create(:allegation, :with_business, business_to_add: business, creator: user) }

  before { sign_in user }

  scenario "removing a business" do
    visit "/cases/#{investigation.pretty_id}/businesses"
    expect(page).to have_summary_item(key: "Trading name",             value: business.trading_name)
    expect(page).to have_summary_item(key: "Legal name",               value: "#{business.legal_name} Registered name")
    expect(page).to have_summary_item(key: "Company number",           value: "#{business.company_number} Registration number for incorporated businesses")

    click_on "Remove this business"

    expect(page).to have_css("p.govuk-body", text: "Remove a business from a case if it's not relevant to the investigation. Business details can be changed from the Businesses tab.")
    expect(page).to have_link("Businesses tab", href: investigation_businesses_path(investigation))
    expect(page).to have_unchecked_field("No")
    expect(page).to have_unchecked_field("Yes")
    expect_to_have_case_breadcrumbs

    click_on "Submit"

    expect(page).to have_error_messages
    expect(page).to have_error_summary "Select yes if you want to remove the business from the case"
    expect_to_have_case_breadcrumbs

    within_fieldset("Do you want to remove the business from the case?") do
      choose "No"
    end
    click_on "Submit"

    expect(page).to have_title("Businesses")
    expect(page).to have_summary_item(key: "Trading name",             value: business.trading_name)
    expect(page).to have_summary_item(key: "Legal name",               value: "#{business.legal_name} Registered name")
    expect(page).to have_summary_item(key: "Company number",           value: "#{business.company_number} Registration number for incorporated businesses")

    click_on "Activity"

    expect(page).not_to have_css("h3", text: "Removed: #{business.trading_name}")

    click_on "Businesses (1)"
    click_on "Remove this business"

    within_fieldset("Do you want to remove the business from the case?") do
      choose "Yes"
      fill_in "Reason for removing the business from the case", with: "This business no longer exists"
    end

    expect_to_have_case_breadcrumbs
    expect(page).to have_link("Cancel", href: investigation_businesses_path(investigation))

    click_on "Submit"

    expect_confirmation_banner("Business was successfully removed.")
    expect(page).to have_css("p.govuk-body", text: "This case has not added any businesses.")

    click_on "Activity"

    expect(page.find("h3", text: "Removed: #{business.trading_name}"))
      .to have_sibling(".govuk-body", text: "This business no longer exists")

    expect(page)
      .to have_link("View business", href: business_path(business))
  end

  scenario "when the business is attached to supporting information" do
    create(:product, investigations: [investigation])
    investigation_product = investigation.investigation_products.first

    corrective_action_params = attributes_for(:corrective_action, business_id: business.id, investigation_product_id: investigation_product.id)
      .merge(user:, investigation:)
    supporting_information = AddCorrectiveActionToCase.call!(corrective_action_params).corrective_action.decorate

    visit "/cases/#{investigation.pretty_id}/businesses"
    expect_to_have_case_breadcrumbs
    click_on "Remove this business"

    expect(page).to have_css(".hmcts-banner__message", text: "Cannot remove the business from the case because it's associated with following supporting information ")
    expect(page).to have_link(supporting_information.supporting_information_title, href: supporting_information.show_path)

    click_on investigation.pretty_id
    click_on "Activity"
    expect(page).not_to have_css("h3", text: "Removed: #{business.trading_name}")
  end
end
