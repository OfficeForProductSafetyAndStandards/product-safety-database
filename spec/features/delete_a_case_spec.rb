require "rails_helper"

RSpec.describe "Deleting a case", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated, :opss_user, name: "Jane Jones") }

  before do
    Investigation.reindex
  end

  context "when case has products associated with it" do
    let!(:investigation) { create(:allegation, :with_products, creator: user, is_closed: false) }

    it "allows user to close the case" do
      sign_in user
      visit "/cases/#{investigation.pretty_id}"

      click_link "Close case"

      expect_to_be_on_close_case_page(case_id: investigation.pretty_id)
    end

    it "does not allow user to delete the case from the cannot close page" do
      sign_in user
      visit "cases/#{investigation.pretty_id}/cannot_close"

      expect(page).to have_css("h1", text: "This case cannot be deleted")
    end

    it "does not allow user to delete the case from the confirm deletion page" do
      sign_in user
      visit "cases/#{investigation.pretty_id}/confirm_deletion"

      expect(page).to have_css("h1", text: "This case cannot be deleted")
    end
  end

  context "when case does not have products associated with it" do
    let!(:investigation) { create(:allegation, creator: user, is_closed: false) }

    it "does not allow user to close case, allows user to delete case" do
      sign_in user

      visit "/cases/#{investigation.pretty_id}"

      click_link "Close case"

      expect_to_be_on_cannot_close_case_page(case_id: investigation.pretty_id)

      click_link "Delete the case"

      expect_to_be_on_confirm_case_deletion_page(case_id: investigation.pretty_id)

      click_button "Delete the case"

      expect(page).to have_current_path("/cases/your-cases")
      expect_confirmation_banner("The case was deleted")
    end
  end
end
