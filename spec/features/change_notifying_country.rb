require "rails_helper"

RSpec.feature "Adding and removing business to a case", :with_stubbed_mailer, :with_stubbed_elasticsearch do
  let(:user)           { create(:user, :activated, team: create(:team, name: "Portsmouth Trading Standards"), name: "Bob Jones") }
  let(:investigation)  { create(:allegation, creator: user) }

  scenario "Change notifying_country with errors" do
    sign_in_and_visit_change_notifying_country_page("")

    click_button "Change"

    expect(page).to have_error_messages
    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Enter the notifying country"

    select "England", from: "Notifying country"
    click_button "Change"
    expect(page.find("dt", text: "Notifying country")).to have_sibling("dd", text: "England")
  end

  scenario "Change pre-populated notifying_country with errors" do
    investigation.update(notifying_country: "Brazil")

    sign_in_and_visit_change_notifying_country_page("Brazil")

    select "Scotland", from: "Notifying country"
    click_button "Change"
    expect(page.find("dt", text: "Notifying country")).to have_sibling("dd", text: "Scotland")
  end

  def sign_in_and_visit_change_notifying_country_page(country)
    sign_in user
    visit "/cases/#{investigation.pretty_id}"
    expect(page.find("dt", text: "Notifying country")).to have_sibling("dd", text: country)
    click_link "Change notifying_country"
    expect(page).to have_css("h1", text: "Change notifying country")
    expect(page).to have_select("Notifying country", selected: country)
  end
end
