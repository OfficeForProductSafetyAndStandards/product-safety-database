require "rails_helper"

RSpec.feature "Changing the notifying country of a case", :with_stubbed_mailer, :with_stubbed_opensearch do
  let(:user)           { create(:user, :activated, team: create(:team, name: "Portsmouth Trading Standards"), name: "Bob Jones") }
  let(:investigation)  { create(:allegation, creator: user) }

  context "when user is a notifying_country_editor" do
    before do
      user.roles.create!(name: "notifying_country_editor")
    end

    # skipping until the notifying country change is carried out on the new case page work.
    xit "can succesfully change pre-populated notifying_country" do
      investigation.update!(notifying_country: "country:GB-ENG")

      sign_in_and_visit_change_notifying_country_page("England")

      select "Scotland", from: "Notifying country"
      click_button "Change"
      expect(page).to have_current_path("/cases/#{investigation.pretty_id}")
      expect(page.find("dt", text: "Notifying country")).to have_sibling("dd", text: "Scotland")

      click_link "Activity"
      expect(page).to have_css("h3", text: "Notifying country changed")
      expect(page).to have_css("p", text: "Notifying country changed from England to Scotland.")
    end
  end

  context "when user is not a notifying_country_editor" do
    xit "does not allow user to change country" do
      sign_in user
      visit "/cases/#{investigation.pretty_id}"
      expect(page.find("dt", text: "Notifying country")).to have_sibling("dd", text: "England")

      expect(page).not_to have_css("h1", text: "Change notifying country")
    end
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
