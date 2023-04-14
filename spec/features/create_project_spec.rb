require "rails_helper"

RSpec.feature "Creating project", :with_stubbed_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  context "when logged in as an OPSS user" do
    let(:title) { Faker::Lorem.sentence }
    let(:summary) { Faker::Lorem.paragraph }
    let(:team) { create(:team) }

    before do
      sign_in(create(:user, :activated, :opss_user, team:))
    end

    scenario "can create a project" do
      visit "/cases/new"

      expect_page_to_have_h1("Create new")
      choose "Project"
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
      expect_page_to_have_h1("Case")
      expect(page.find("dt", text: "Case name")).to have_sibling("dd", text: title)
      expect(page.find("dt", text: "Summary")).to have_sibling("dd", text: summary)
      expect(page.find("dt", text: "Notifying country")).to have_sibling("dd", text: "England")

      click_on "Activity"
      expect_details_on_activity_page(title, summary)

      investigation = Investigation.last

      expect(delivered_emails.last.personalization).to eq({
        name: User.first.name,
        case_title: investigation.user_title,
        case_type: "project",
        capitalized_case_type: "Project",
        case_id: investigation.pretty_id,
        investigation_url: investigation_url(investigation)
      })
      expect(delivered_emails.last.template).to eq "b5457546-9633-4a9c-a844-b61f2e818c24"
    end

    def expect_details_on_activity_page(title, summary)
      within ".timeline .govuk-list" do
        expect(page).to have_css("h3",           text: "Project logged: #{title}")
        expect(page).to have_css("p.govuk-body", text: summary, exact_text: true)
      end
    end
  end
end
