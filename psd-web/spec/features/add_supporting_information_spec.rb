require "rails_helper"

RSpec.feature "Add supporting information", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user)          { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:allegation, owner: user.team) }

  scenario "Adding a comment" do
    commentator = create(:user, :activated, has_viewed_introduction: true, team: user.team)

    sign_in commentator

    visit "/cases/#{investigation.pretty_id}/supporting-information"
    click_link "Add supporting information"

    expect_to_be_on_add_supporting_information_page
    click_button "Continue"

    expect(page).to have_content("Supporting information type must not be empty")
    choose "Comment"
    click_button "Continue"

    expect_to_be_on_new_comment_page
    comment = Faker::Lorem.sentence
    fill_in "body", with: comment
    click_button "Continue"

    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    expect_confirmation_banner("Comment was successfully added.")
    click_link "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect(page).to have_css("p", text: comment)
  end
end
