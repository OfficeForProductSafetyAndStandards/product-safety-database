require "rails_helper"

RSpec.feature "Creating project", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  context "when login as an OPSS user" do
    let(:title) { Faker::Lorem.sentence }
    let(:summary) { Faker::Lorem.paragraph }

    before do
      sign_in(create(:user, :activated, :opss_user))
    end

    scenario "can create a project" do
      visit "/cases"

      click_link "Open a new case"

      expect_page_to_have_h1("Create new")
      choose "Project"
      click_button "Continue"

      expect_to_be_on_coronavirus_page("/investigation/project/coronavirus")
      click_button "Continue"

      expect_to_be_on_coronavirus_page("/investigation/project/coronavirus")
      expect(page).to have_error_messages
      expect(page).to have_error_summary "Select whether or not the case is related to the coronavirus outbreak"

      choose "Yes, it is (or could be)"
      click_button "Continue"

      expect_page_to_have_h1("New project")
      click_button "Create project"

      expect_page_to_have_h1("New project")
      expect(page).to have_error_messages
      expect(page).to have_error_summary "User title cannot be blank"
      expect(page).to have_error_summary "Description cannot be blank"

      fill_in "Please provide a title", with: title
      fill_in "Project summary", with: summary
      click_button "Create project"

      expect_confirmation_banner("Project was successfully created")
      expect_page_to_have_h1("Overview")
      expect(page).to have_css("p", text: title)
      expect(page).to have_css("p", text: summary)
      expect(page.find("dt", text: "Coronavirus related"))
        .to have_sibling("dd", text: "Coronavirus related case")
    end
  end
end
