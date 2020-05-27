require "rails_helper"

RSpec.feature "Ability to edit an investigation", :with_elasticsearch, :with_stubbed_mailer, type: :feature do
  let(:investigation) { create(:project, owner: user.team) }
  let(:user) { create(:user, :activated) }
  let(:other_user) { create(:user, :activated) }

  scenario "allows to edit some the attributes" do
    sign_in user
    visit investigation_path(investigation)
    expect(page).to have_link("Change summary", href: "/cases/#{investigation.pretty_id}/edit_summary")

    click_link "Change summary"

    fill_in "investigation[description]", with: "new description"
    click_on "Update summary"

    expect(page).to have_css("p", text: "new description")

    click_on "Change coronavirus status"

    choose "Yes, it is (or could be)"
    click_on "Update coronavirus status"

    expect_confirmation_banner("Coronavirus status updated on project")
    expect(page).to have_css(".govuk-summary-list__row .govuk-summary-list__key + .govuk-summary-list__value", text: "Coronavirus related case")
  end

  scenario "user from other team cannot edit summary and corona virus flag" do
    sign_in other_user
    visit investigation_path(investigation)
    expect(page).not_to have_link("Change summary")
    expect(page).not_to have_link("Change coronavirus status")
  end
end
