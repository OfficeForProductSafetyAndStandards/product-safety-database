require "rails_helper"

RSpec.feature "Ability to edit an investigation", :with_elasticsearch, :with_stubbed_mailer, type: :feature do
  let(:investigation) { create(:project, owner: user) }
  let(:user) { create(:user, :activated) }

  before { sign_in user }

  scenario "allows to edit some the attributes" do
    visit investigation_path(investigation)

    click_link "Change summary"

    fill_in "investigation[description]", with: "new description"
    click_on "Update summary"

    expect(page).to have_css("p", text: "new description")

    click_on "Change coronavirus status"

    choose "Yes, it is (or could be)"
    click_on "Update coronavirus status"

    expect(page).to have_css(".govuk-summary-list__row .govuk-summary-list__key + .govuk-summary-list__value", text: "Coronavirus related case")
  end
end
