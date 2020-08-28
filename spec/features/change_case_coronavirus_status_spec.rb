require "rails_helper"

RSpec.feature "Editing the case coronavirus flag", :with_elasticsearch, :with_stubbed_mailer, type: :feature do
  let(:investigation) { create(:project, creator: user) }
  let(:user) { create(:user, :activated) }
  let(:other_user) { create(:user, :activated) }

  scenario "user on same team as owner" do
    sign_in user
    visit investigation_path(investigation)
    click_on "Change coronavirus status"

    choose "Yes, it is (or could be)"
    click_on "Update coronavirus status"

    expect_confirmation_banner("Coronavirus status updated on project")
    expect(page).to have_css(".govuk-summary-list__row .govuk-summary-list__key + .govuk-summary-list__value", text: "Coronavirus related case")
  end

  scenario "user from other team cannot edit coronavirus flag" do
    sign_in other_user
    visit investigation_path(investigation)
    expect(page).not_to have_link("Change coronavirus status")
  end
end
