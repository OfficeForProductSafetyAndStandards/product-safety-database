require "rails_helper"

RSpec.feature "Delete a business from a case", :with_stubbed_elasticsearch, :with_stubbed_mailer do
  let(:business)      { create(:business) }
  let(:user)          { create(:user, :activated, has_accepted_declaration: true) }
  let(:investigation) { create(:allegation, :with_business, business_to_add: business, creator: user) }

  before { sign_in user }

  scenario "delete a business" do
    visit "/cases/#{investigation.pretty_id}/businesses"

    expect(page).to have_summary_item(key: "Trading name",             value: business.trading_name)
    expect(page).to have_summary_item(key: "Registered or legal name", value: business.legal_name)
    expect(page).to have_summary_item(key: "Company number",           value: business.company_number)
    expect(page).to have_summary_item(key: "Address",                  value: business.primary_location&.summary)
    expect(page).to have_summary_item(key: "Contact",                  value: business.primary_contact&.summary)

    click_on "Remove business"

    expect(page).to have_css("p.govuk-body", text: "Remove a business from a case if it's not relevant to the investigation. Business details can be changed from the Businesses tab.")
    expect(page).to have_link("Businesses tab", href: investigation_businesses_path(investigation))
    expect(page).to have_unchecked_field("No")
    expect(page).to have_unchecked_field("Yes")

    click_on "Remove business"

    expect(page).to have_error_messages
    expect(page).to have_error_summary "Select yes if you want to remove the business from the case"

    within_fieldset("Do you want to remove the business from the case?") do
      choose "No"
    end
    click_on "Remove business"

    expect(page).to have_title("Businesses")
    expect(page).to have_summary_item(key: "Trading name",             value: business.trading_name)
    expect(page).to have_summary_item(key: "Registered or legal name", value: business.legal_name)
    expect(page).to have_summary_item(key: "Company number",           value: business.company_number)
    expect(page).to have_summary_item(key: "Address",                  value: business.primary_location&.summary)
    expect(page).to have_summary_item(key: "Contact",                  value: business.primary_contact&.summary)


    click_on "Activity"

    expect(page).not_to have_css("h3", text: "Removed: #{business.trading_name}")

    click_on "Businesses (1)"
    click_on "Remove business"

    within_fieldset("Do you want to remove the business from the case?") do
      choose "Yes"
      fill_in "Reason for removing the business from the case", with: "This business no longer exists"
    end

    expect(page).to have_link("Cancel", href: investigation_businesses_path(investigation))

    click_on "Remove business"

    expect(page).to have_css(".hmcts-banner__message", text: "Business was successfully removed.")
    expect(page).to have_css("p.govuk-body", text: "No businesses")

    click_on "Activity"

    expect(page.find("h3", text: "Removed: #{business.trading_name}"))
      .to have_sibling(".govuk-body", text: "This business no longer exists")
  end

  scenario "when the business is attached to supporting information" do
    product = create(:product, investigations: [investigation])
    corrective_action_params = attributes_for(:corrective_action, business_id: business.id, product_id: product.id)
      .merge(user: user, investigation: investigation)
    AddCorrectiveActionToCase.call!(corrective_action_params).corrective_action

    visit "/cases/#{investigation.pretty_id}/businesses"

    click_on "Remove business"

    expect(page).to have_css(".hmcts-banner__message", text: "Cannot remove the business from the case because it's associated with following supporting information ")
  end
end
