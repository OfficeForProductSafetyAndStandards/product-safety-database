require "rails_helper"

RSpec.feature "Case permissions management", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user) {
    create(:user,
           :activated,
           teams: [create(:team, name: "Portsmouth Trading Standards")])
  }

  let(:investigation) {
    create(:investigation,
           assignee: user)
  }

  before do
    create(:team, name: "Southampton Trading Standards")
  end

  scenario "Adding a team to a case" do
    sign_in user

    visit "/cases/#{investigation.pretty_id}"

    click_link "Add team"

    expect_to_be_on_add_team_to_case_page(case_id: investigation.pretty_id)

    select "Southampton Trading Standards", from: "Choose team"
    within_fieldset "Do you want to include instructions or more information?" do
      choose "Yes, add a message"
    end

    fill_in "Message to the team", with: "Thanks for collaborating on this case with us."

    click_button "Add team to this case"

    expect_to_be_on_case_page(case_id: investigation.pretty_id)

    expect(page).to have_summary_item(key: "Teams added to case", value: "Southampton Trading Standards Portsmouth Trading Standards")
  end

private

  def expect_to_be_on_case_page(case_id:)
    expect(page).to have_current_path("/cases/#{case_id}")
    expect(page).to have_selector("h1", text: "Overview")
  end

  def expect_to_be_on_add_team_to_case_page(case_id:)
    expect(page).to have_current_path("/cases/#{case_id}/teams/add")
    expect(page).to have_selector("h1", text: "Add a team to the case")
  end
end
