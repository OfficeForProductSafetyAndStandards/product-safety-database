require "rails_helper"

RSpec.feature "Notification summary screen", :with_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  let!(:user) { create(:user, :opss_user, :activated, has_viewed_introduction: true, roles: %w[notification_task_list_user]) }
  let!(:product_one) { create(:product_washing_machine, name: "MyBrand Washing Machine") }
  let!(:notification) { create(:notification, :with_business, products: [product_one], creator: user, reported_reason: "unsafe_and_non_compliant", hazard_type: "Burns", hazard_description: "FIRE", non_compliant_reason: "danger") }

  before do
    sign_in(user)
  end

  scenario "shows data properly" do
    visit "/notifications/your-notifications"
    click_link "Update notification"
    expect(page).to have_selector("h1", text: notification.user_title)

    expect(page).to have_content("Notification number: #{notification.pretty_id}")
    expect(page).to have_content(/Last updated: .*/)
    expect(page).to have_content("Created: #{notification.created_at.strftime('%-d %B %Y')}")
  end

  context "when submitted date has valid date" do
    before do
      notification.update!(submitted_at: Time.zone.now.utc)
      visit "/notifications/your-notifications"
      click_link "Update notification"
    end

    it "displays the submitted date" do
      expect(page).to have_content("Submitted: #{notification.submitted_at.strftime('%-d %B %Y')}")
    end
  end

  context "when submitted date is nil" do
    before do
      notification.update!(submitted_at: nil)
      visit "/notifications/your-notifications"
      click_link "Update notification"
    end

    it "displays 'Not provided' for the submitted date" do
      expect(page).to have_content("Submitted: Not provided")
    end
  end
end
