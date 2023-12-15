require "rails_helper"

RSpec.describe "Deleting a notification", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated, :opss_user, name: "Jane Jones") }

  before do
    Investigation.reindex
  end

  context "when notification has products associated with it" do
    let!(:investigation) { create(:allegation, :with_products, creator: user, is_closed: false) }

    it "allows user to close the notification" do
      sign_in user
      visit "/cases/#{investigation.pretty_id}"

      click_link "Close notification"

      expect_to_be_on_close_case_page(case_id: investigation.pretty_id)
    end

    it "does not allow user to delete the notification from the cannot close page" do
      sign_in user
      visit "cases/#{investigation.pretty_id}/cannot_close"

      expect(page).to have_css("h1", text: "This notification cannot be deleted")
    end

    it "does not allow user to delete the notification from the confirm deletion page" do
      sign_in user
      visit "cases/#{investigation.pretty_id}/confirm_deletion"

      expect(page).to have_css("h1", text: "This notification cannot be deleted")
    end
  end

  context "when notification does not have products associated with it" do
    let!(:investigation) { create(:allegation, creator: user, is_closed: false) }

    it "does not allow user to close notification, allows user to delete notification" do
      sign_in user

      visit "/cases/#{investigation.pretty_id}"

      click_link "Close notification"

      expect_to_be_on_cannot_close_case_page(case_id: investigation.pretty_id)

      click_link "Delete the notification"

      expect_to_be_on_confirm_case_deletion_page(case_id: investigation.pretty_id)

      click_button "Delete the notification"

      expect(page).to have_current_path("/cases/your-cases")
      expect_confirmation_banner("The notification was deleted")
    end
  end
end
