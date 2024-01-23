require "rails_helper"

RSpec.feature "Changing a notification's notifying country", :with_stubbed_mailer, :with_stubbed_opensearch do
  let(:user)           { create(:user, :activated, team: create(:team, name: "Portsmouth Trading Standards"), name: "Bob Jones") }
  let(:notification)  { create(:notification, creator: user) }

  context "when user is a notifying_country_editor" do
    before do
      user.roles.create!(name: "notifying_country_editor")
    end

    it "can succesfully change pre-populated notifying country" do
      notification.update!(notifying_country: "country:GB-ENG")

      sign_in_and_visit_change_notifying_country_page("England")

      select "Scotland", from: "Select which country or collection of countries"
      click_button "Save"
      expect(page).to have_current_path("/cases/#{notification.pretty_id}")
      expect(page.find("dt", text: "Notifying country")).to have_sibling("dd", text: "Scotland")

      click_link "Activity"
      expect(page).to have_css("h3", text: "Notifying country changed")
      expect(page).to have_css("p", text: "Notifying country changed from England to Scotland")
    end
  end

  context "when user is not a notifying_country_editor" do
    it "does not allow user to change notifying country" do
      sign_in user
      visit "/cases/#{notification.pretty_id}"
      expect(page.find("dt", text: "Notifying country")).to have_sibling("dd", text: "England")

      expect(page).not_to have_css("h1", text: "Change the notifying country")
    end
  end

  def sign_in_and_visit_change_notifying_country_page(country)
    sign_in user
    visit "/cases/#{notification.pretty_id}"
    expect(page.find("dt", text: "Notifying country")).to have_sibling("dd", text: country)
    click_link "Change notifying country"
    expect(page).to have_css("h1", text: "Change the notifying country")
    within_fieldset "Change the notifying country" do
      choose "UK nations"
    end
    expect(page).to have_select("Select which country or collection of countries", selected: country)
    expect_to_have_notification_breadcrumbs
  end
end
