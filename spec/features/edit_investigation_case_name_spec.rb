require "rails_helper"

RSpec.feature "Edit an investigation's case name", :with_opensearch, :with_stubbed_mailer do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:original_case_name) { "the original case name" }
  let(:new_case_name) { "new name" }
  let(:taken_case_name) { "case name that has already been taken" }
  let(:investigation) { create(:allegation, user_title: original_case_name, creator: user) }

  before do
    create(:allegation, user_title: taken_case_name, creator: user)
  end

  it "allows user to edit reference number" do
    sign_in(user)
    visit "/cases/#{investigation.pretty_id}"

    click_link "Edit case name"

    expect(page).to have_current_path "/cases/#{investigation.pretty_id}/case_names/edit", ignore_query: true
    expect(page).to have_css("h1", text: "Edit the case name")

    expect(page).to have_field("user_title", with: original_case_name)

    fill_in :user_title, with: ""

    click_button "Save"

    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Enter a case name"

    fill_in :user_title, with: taken_case_name

    click_button "Save"

    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "The case name has already been used in an open case by your team"

    fill_in :user_title, with: new_case_name

    click_button "Save"

    expect(page).to have_current_path "/cases/#{investigation.pretty_id}", ignore_query: true
    expect(page).to have_content "Case name was successfully updated"

    expect(page.find("dt", text: "Case name")).to have_sibling("dd", text: new_case_name)
  end
end
