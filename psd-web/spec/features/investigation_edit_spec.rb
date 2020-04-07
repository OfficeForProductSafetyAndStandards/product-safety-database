require "rails_helper"

RSpec.feature "Ability to edit an investigation", :with_elasticsearch, :with_stubbed_mailer, :with_stubbed_keycloak_config, type: :feature do
  let(:investigation) { create(:enquiry) }

  before do
    sign_in
  end

  scenario "allows to edit some the attributes" do
    visit investigation_path(investigation)

    click_link "Change summary"

    fill_in "investigation[description]", with: "new description"
    click_on "Update summary"

    expect(page).to have_css("p", text: "new description")

    change_link = page.find(".govuk-summary-list__row .govuk-summary-list__key", text: "Coronavirus related").sibling("govuk-summary-list__actions a")

    click_on change_link

    save_and_open_page
  end
end
