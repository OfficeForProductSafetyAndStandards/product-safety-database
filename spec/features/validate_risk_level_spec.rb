require "rails_helper"

RSpec.feature "Validate risk level", :with_elasticsearch, :with_stubbed_mailer, type: :feature do
  let(:investigation) { create(:project, creator: user) }
  let(:user) { create(:user, :activated) }
  let(:other_user) { create(:user, :activated) }

  scenario "validate the level" do
    sign_in user
    visit investigation_path(investigation)

    click_link "Validate"

    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/validate-risk-level/edit")

    click_on "Submit Button"

    expect(page).to have_content("Select yes if you have validated the case risk level")

    within_fieldset("Have you validated the case risk level?") do
      choose "Yes"
    end

    click_on "Continue"

    expect(page).to have_current_path("/cases/#{investigation.pretty_id}")
    expect(page).to have_content("Case risk level validated")
    expect(page).to have_content("Validated by #{user.team.name} on #{investigation.risk_validated_at}")
    expect(page).not_to have_link("Validate")
  end

  scenario "do not validate the level" do
    sign_in user
    visit investigation_path(investigation)

    click_link "Validate"

    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/validate-risk-level/edit")

    within_fieldset("Have you validated the case risk level?") do
      choose "No"
    end

    click_on "Continue"

    expect(page).to have_current_path("/cases/#{investigation.pretty_id}")
    expect(page).not_to have_content("Case risk level validated")
    expect(page).not_to have_content("Validated by #{user.team.name} on #{investigation.risk_validated_at}")
    expect(page).to have_link("Validate")
  end
end
