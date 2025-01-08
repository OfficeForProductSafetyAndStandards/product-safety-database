require "rails_helper"

RSpec.feature "Changing the status of a notification", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let!(:notification) { create(:notification, :with_products, creator: creator_user, is_closed: false) }
  let(:user) { create(:user, :activated, :opss_user, name: "Jane Jones") }
  let(:creator_user) { create(:user, :opss_user, :activated, email: "test@example.com") }
  let(:other_team) { create(:team) }

  before do
    ChangeNotificationOwner.call!(notification:, owner: user, user:)
    delivered_emails.clear
  end

  context "when closing a notification with no products associated with it" do
    let!(:no_product_notification) { create(:notification, creator: creator_user, is_closed: false) }

    it "does not allow closing of notification" do
      sign_in creator_user
      visit "/cases/#{no_product_notification.pretty_id}"

      click_link "Close notification"

      expect_to_be_on_cannot_close_case_page(case_id: no_product_notification.pretty_id)
    end
  end

  context "when case has products associated with it" do
    let(:product) { create(:product) }

    scenario "Closing and re-opening a notification via different routes" do
      sign_in user
      visit "/cases/#{notification.pretty_id}"

      click_link "Close this notification"

      expect_to_be_on_close_case_page(case_id: notification.pretty_id)
      expect_to_have_notification_breadcrumbs

      # Navigate via the case overview table
      visit "/cases/#{notification.pretty_id}"

      within("div.opss-text-align-right") do
        expect(page).to have_link "Close notification"
        expect(page).not_to have_link "Re-open notification"
        click_link "Close notification"
      end

      expect_to_be_on_close_case_page(case_id: notification.pretty_id)
      expect_to_have_notification_breadcrumbs

      fill_in "Why are you closing the notification?", with: "Notification has been resolved."

      click_button "Close notification"

      expect_to_be_on_case_page(case_id: notification.pretty_id)
      expect_confirmation_banner("The notification was closed")
      expect(page).to have_summary_item(key: "Status", value: "Notification closed (#{Date.current.to_formatted_s(:govuk)})")

      click_link "Activity"

      expect_to_be_on_case_activity_page(case_id: notification.pretty_id)
      expect(page).to have_css("h3", text: "Notification closed")
      expect(page).to have_css("p", text: "Notification has been resolved.")

      # Check the close page shows an error if trying to revisit it
      visit "/cases/#{notification.pretty_id}/status/close"
      expect(page).to have_css("h1", text: "Close notification")
      expect(page).to have_css("p", text: "The notification is already closed. Do you want to re-open it?")
      expect_to_have_notification_breadcrumbs

      visit "/cases/#{notification.pretty_id}"

      within("div.opss-text-align-right") do
        expect(page).not_to have_link "Close notification"
        expect(page).to have_link "Re-open notification"
        click_link "Re-open notification"
      end

      expect_to_be_on_reopen_case_page(case_id: notification.pretty_id)
      expect_to_have_notification_breadcrumbs

      fill_in "Why are you re-opening the notification?", with: "Notification has not been resolved."

      click_button "Re-open notification"

      expect_to_be_on_case_page(case_id: notification.pretty_id)

      expect_confirmation_banner("The notification was re-opened")
      expect(page).to have_summary_item(key: "Status", value: "Open")

      click_link "Activity"

      expect_to_be_on_case_activity_page(case_id: notification.pretty_id)
      expect(page).to have_css("h3", text: "Notification re-opened")
      expect(page).to have_css("p", text: "Notification has not been resolved.")

      # Check the close page shows an error if trying to revisit it
      visit "/cases/#{notification.pretty_id}/status/reopen"
      expect(page).to have_css("h1", text: "Re-open notification")
      expect(page).to have_css("p", text: "The notification is already open. Do you want to close it?")
    end

    context "when closing the notification with a product with another open notification attached to it" do
      let(:other_notification) { create(:notification, creator: user, is_closed: false, products: [product]) }

      before do
        sign_in user
        visit "/cases/#{other_notification.pretty_id}"
        click_link "Close this notification"
        fill_in "Why are you closing the notification?", with: "Notification has been resolved."
        click_button "Close notification"

        visit "/products/#{product.id}"
      end

      context "when the product is owned by the user's team" do
        let(:product) { create(:product, name: "blahblahblah", owning_team_id: user.team.id) }

        it "makes the notification unowned" do
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

    context "when closing the notification with a product with a closed notification attached to it" do
      let(:other_notification) { create(:allegation, creator: user, products: [product]) }

      before do
        ChangeNotificationStatus.call!(notification:, new_status: "closed", user:)
        sign_in user
        visit "/cases/#{other_notification.pretty_id}"

        click_link "Close this notification"
        fill_in "Why are you closing the notification?", with: "Notification has been resolved."
        click_button "Close notification"

        visit "/products/#{product.id}"
      end

      context "when the product is owned by the user's team" do
        let(:product) { create(:product, name: "blahblahblah", owning_team_id: user.team.id) }

        it "makes the notification unowned" do
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
