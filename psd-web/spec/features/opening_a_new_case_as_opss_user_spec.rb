require "rails_helper"

RSpec.feature "Opening a new case", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated, :opss_user) }

  scenario "Opening a new case (with validation error)" do
    sign_in(user)

    visit "/cases"

    click_link "Open a new case"

    expect_to_be_on_new_case_page

    click_button "Continue"

    expect(page).to have_text("Please select an option before continuing")

    within_fieldset("What are you creating?") do
      choose "Project"
    end

    click_button "Continue"

    expect_to_be_on_coronavirus_page("/project/coronavirus")

    # The detailed flows for each of the separate case types (allegation,
    # project and enquiry) are each covered as separate scenarios.
  end
end
