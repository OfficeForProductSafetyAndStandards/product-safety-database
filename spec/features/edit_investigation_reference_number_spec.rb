require "rails_helper"

RSpec.feature "Edit an investigation's reference number", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:team_mate) { create(:user, :activated, has_viewed_introduction: true, team: user.team) }
  let(:original_reference_number) { "123" }
  let(:new_reference_number) { "999" }
  let(:investigation) { create(:allegation, complainant_reference: original_reference_number, creator: user) }

  it "allows user to edit reference number" do
    sign_in(team_mate)
    visit "/cases/#{investigation.pretty_id}"

    click_link "Edit reference number"

    expect(page).to have_current_path "/cases/#{investigation.pretty_id}/reference_numbers/edit", ignore_query: true
    expect(page).to have_css("h1", text: "Edit the reference number")

    expect(page).to have_field("complainant_reference", with: original_reference_number)

    fill_in :complainant_reference, with: new_reference_number

    click_button "Save"

    expect(page).to have_current_path "/cases/#{investigation.pretty_id}", ignore_query: true
    expect(page).to have_content "Reference number was successfully updated"

    expect(page.find("dt", text: "Trading Standards reference")).to have_sibling("dd", text: new_reference_number)

    click_link "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect(page).to have_css("h3", text: "Reference number updated")
    expect(page).to have_content("Reference number: #{new_reference_number}")

    expect(delivered_emails.last.personalization[:subject_text]).to eq "Allegation reference number updated"
  end
end
