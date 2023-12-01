require "rails_helper"

RSpec.feature "Edit an case's reference number", :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:team_mate) { create(:user, :activated, has_viewed_introduction: true, team: user.team) }
  let(:original_reference_number) { "123" }
  let(:new_reference_number) { "999" }
  let(:investigation) { create(:allegation, complainant_reference: original_reference_number, creator: user) }

  it "allows user to edit reference number" do
    sign_in(team_mate)
    visit "/cases/#{investigation.pretty_id}"

    click_link "Edit the reference number"

    expect(page).to have_current_path "/cases/#{investigation.pretty_id}/reference_numbers/edit", ignore_query: true
    expect(page).to have_css("h1", text: "Edit the reference number")
    expect(page).to have_field("complainant_reference", with: original_reference_number)
    expect_to_have_notification_breadcrumbs

    fill_in :complainant_reference, with: new_reference_number

    click_button "Save"

    expect(page).to have_current_path "/cases/#{investigation.pretty_id}", ignore_query: true
    expect(page).to have_content "The reference number was updated"

    expect(page.find("dt", text: "Reference")).to have_sibling("dd", text: new_reference_number)
  end
end
