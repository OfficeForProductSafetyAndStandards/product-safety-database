require "rails_helper"

RSpec.feature "Adding and removing business to a case", :with_stubbed_mailer, :with_stubbed_elasticsearch do
  let(:user)           { create(:user, :activated, team: create(:team, name: "Portsmouth Trading Standards"), name: "Bob Jones") }
  let(:investigation)  { create(:allegation, creator: user, notifying_country: "Brazil") }

  scenario "Change notifying_country" do
    sign_in user
    visit "/cases/#{investigation.pretty_id}"
    expect(page.find("dt", text: "Notifying country")).to have_sibling("dd", text: "Brazil")

    click_link "Change notifying_country"
    select "Scotland", from: "Change notifying country"
    click_button "Submit Button"
    expect(page.find("dt", text: "Notifying country")).to have_sibling("dd", text: "Scotland")
  end
end
