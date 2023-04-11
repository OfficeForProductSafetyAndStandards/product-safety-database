require "rails_helper"

RSpec.feature "Changing the status of a case", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let!(:investigation) { create(:allegation, :with_products, creator: creator_user, is_closed: false) }
  let(:user) { create(:user, :activated, :opss_user, name: "Jane Jones") }
  let(:creator_user) { create(:user, :opss_user, :activated, email: "test@example.com") }
  let(:other_team) { create(:team) }

  before do
    ChangeCaseOwner.call!(investigation:, owner: user, user:)
    delivered_emails.clear
  end

  context "when closing a case with no products associated with it" do
    let!(:no_product_investigation) { create(:allegation, creator: creator_user, is_closed: false) }

    it "does not allow closing of case" do
      sign_in creator_user
      visit "/cases/#{no_product_investigation.pretty_id}"

      click_link "Close case"

      expect_to_be_on_cannot_close_case_page(case_id: no_product_investigation.pretty_id)
    end
  end

  context "when case has products associated with it" do
    let(:product) { create(:product) }

    scenario "Closing and re-opening a case via different routes" do
      sign_in user
      visit "/cases/#{investigation.pretty_id}"

      click_link "Close this case"

      expect_to_be_on_close_case_page(case_id: investigation.pretty_id)

      # Navigate via the case overview table
      visit "/cases/#{investigation.pretty_id}"

      within("div.opss-text-align-right") do
        expect(page).to have_link "Close case"
        expect(page).not_to have_link "Re-open case"
        click_link "Close case"
      end

      expect_to_be_on_close_case_page(case_id: investigation.pretty_id)

      fill_in "Why are you closing the case?", with: "Case has been resolved."

      click_button "Close case"

      expect_to_be_on_case_page(case_id: investigation.pretty_id)
      expect_confirmation_banner("The case was closed")
      expect(page).to have_summary_item(key: "Status", value: "Case closed #{Date.current.to_formatted_s(:govuk)}")

      click_link "Activity"

      expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
      expect(page).to have_css("h3", text: "Allegation closed")
      expect(page).to have_css("p", text: "Case has been resolved.")

      # Check the close page shows an error if trying to revisit it
      visit "/cases/#{investigation.pretty_id}/status/close"
      expect(page).to have_css("h1", text: "Close case")
      expect(page).to have_css("p", text: "The allegation is already closed. Do you want to re-open it?")

      visit "/cases/#{investigation.pretty_id}"

      within("div.opss-text-align-right") do
        expect(page).not_to have_link "Close case"
        expect(page).to have_link "Re-open case"
        click_link "Re-open case"
      end

      expect_to_be_on_reopen_case_page(case_id: investigation.pretty_id)

      fill_in "Why are you re-opening the case?", with: "Case has not been resolved."

      click_button "Re-open case"

      expect_to_be_on_case_page(case_id: investigation.pretty_id)

      expect_confirmation_banner("The case was re-opened")
      expect(page).to have_summary_item(key: "Status", value: "Open")

      click_link "Activity"

      expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
      expect(page).to have_css("h3", text: "Allegation re-opened")
      expect(page).to have_css("p", text: "Case has not been resolved.")

      # Check the close page shows an error if trying to revisit it
      visit "/cases/#{investigation.pretty_id}/status/reopen"
      expect(page).to have_css("h1", text: "Re-open case")
      expect(page).to have_css("p", text: "The allegation is already open. Do you want to close it?")
    end

    context "when closing the case with a product with another open investigation attached to it" do
      let(:other_investigation) { create(:allegation, creator: user, is_closed: false, products: [product]) }

      before do
        sign_in user
        visit "/cases/#{other_investigation.pretty_id}"

        click_link "Close this case"

        fill_in "Why are you closing the case?", with: "Case has been resolved."

        click_button "Close case"

        visit "/products/#{product.id}"
      end

      context "when the product is owned by the user's team" do
        let(:product) { create(:product, name: "blahblahblah", owning_team_id: user.team.id) }

        it "makes the case unowned" do
          expect(page).to have_summary_item(key: "Product record owner", value: "No owner")
        end
      end

      context "when the product is owned by another team" do
        let(:product) { create(:product, owning_team_id: other_team.id, name: "helloworld") }

        it "does not change the product owner" do
          expect(page).to have_summary_item(key: "Product record owner", value: other_team.name)
        end
      end
    end

    context "when closing the case with a product with a closed investigation attached to it" do
      let(:other_investigation) { create(:allegation, creator: user, products: [product]) }

      before do
        ChangeCaseStatus.call!(investigation:, new_status: "closed", user:)
        sign_in user
        visit "/cases/#{other_investigation.pretty_id}"

        click_link "Close this case"

        fill_in "Why are you closing the case?", with: "Case has been resolved."

        click_button "Close case"

        visit "/products/#{product.id}"
      end

      context "when the product is owned by the user's team" do
        let(:product) { create(:product, name: "blahblahblah", owning_team_id: user.team.id) }

        it "makes the case unowned" do
          expect(page).to have_summary_item(key: "Product record owner", value: "No owner")
        end
      end

      context "when the product is owned by another team" do
        let(:product) { create(:product, owning_team_id: other_team.id, name: "helloworld") }

        it "does not change the product owner" do
          expect(page).to have_summary_item(key: "Product record owner", value: other_team.name)
        end
      end
    end
  end
end
