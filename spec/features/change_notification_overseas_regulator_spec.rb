require "rails_helper"

RSpec.feature "Changing the overseas regulator of a notification", :with_stubbed_mailer, :with_stubbed_opensearch do
  let(:user) { create(:user, :activated, team: create(:team, name: "Portsmouth Trading Standards"), name: "Bob Jones") }
  let(:notification) { create(:notification, creator: user) }

  context "when user is an OPSS member" do
    before do
      user.roles.create!(name: "opss")
    end

    it "can succesfully set the overseas regulator" do
      sign_in_and_visit_change_overseas_regulator_page("")

      choose "Yes"
      select "Armenia", from: "Select which country"
      click_button "Save"
      expect(page).to have_current_path("/cases/#{notification.pretty_id}")
      expect(page.find("dt", text: "Overseas regulator")).to have_sibling("dd", text: "Armenia")

      click_link "Activity"
      expect(page).to have_css("h3", text: "Overseas regulator changed")
      expect(page).to have_css("p", text: "Overseas regulator set to Armenia")
    end

    it "can succesfully change the pre-populated overseas regulator" do
      notification.update!(is_from_overseas_regulator: true, overseas_regulator_country: "country:AM")

      sign_in_and_visit_change_overseas_regulator_page("Armenia")

      select "United States", from: "Select which country"
      click_button "Save"
      expect(page).to have_current_path("/cases/#{notification.pretty_id}")
      expect(page.find("dt", text: "Overseas regulator")).to have_sibling("dd", text: "United States")

      click_link "Activity"
      expect(page).to have_css("h3", text: "Overseas regulator changed")
      expect(page).to have_css("p", text: "Overseas regulator changed from Armenia to United States")
    end

    it "can succesfully clear the pre-populated overseas regulator" do
      notification.update!(is_from_overseas_regulator: true, overseas_regulator_country: "country:AM")

      sign_in_and_visit_change_overseas_regulator_page("Armenia")

      choose "No"
      click_button "Save"
      expect(page).to have_current_path("/cases/#{notification.pretty_id}")
      expect(page.find("dt", text: "Overseas regulator")).to have_sibling("dd", text: "No")

      click_link "Activity"
      expect(page).to have_css("h3", text: "Overseas regulator changed")
      expect(page).to have_css("p", text: "Overseas regulator changed from Armenia to None")
    end
  end

  context "when user is not an OPSS member" do
    it "does not allow user to view or change the overseas regulator" do
      sign_in user
      visit "/cases/#{notification.pretty_id}"
      expect(page).not_to have_css("dt", text: "Overseas regulator")
    end
  end

  def sign_in_and_visit_change_overseas_regulator_page(country)
    sign_in user
    visit "/cases/#{notification.pretty_id}"
    expect(page.find("dt", text: "Overseas regulator")).to have_sibling("dd", text: country)
    click_link "Change overseas regulator"
    expect(page).to have_css("h1", text: "Was the allegation made by an overseas regulator?")
    expect(page).to have_select("Select which country", selected: country)
    expect_to_have_notification_breadcrumbs
  end
end
