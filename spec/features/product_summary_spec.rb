require "rails_helper"

RSpec.describe "Product Summary", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:user) { create :user, :opss_user, :activated, has_viewed_introduction: true, roles: %w[notification_task_list_user] }
  let!(:iphone) { create(:product_iphone, brand: "Apple", created_at: 1.day.ago, authenticity: "counterfeit") }
  let!(:investigation) { create(:notification, products: [iphone], hazard_type: "Cuts") }
  let!(:second_investigation) { create(:notification, products: [iphone], hazard_type: "Cuts") }

  before do
    sign_in(user)
  end

  context "when viewing the product summary page" do
    scenario "with two notifications" do
      visit products_path
      expect(page).to have_content "There are currently 1 product."

      visit "/products/#{iphone.id}"
      expect(page).to have_text("This product record has been added to 2 notifications")

      expect(page).to have_link(investigation.title, href: "/cases/#{investigation.pretty_id}")
      expect(page).to have_link(investigation.title, href: "/cases/#{second_investigation.pretty_id}")
    end

    scenario "does not show draft notifications" do
      create_a_draft_notification
      visit "/notifications/your-notifications"

      expect(page).to have_content("Draft notifications")
      expect(page).to have_content("Fake name")
      expect(page).to have_content(iphone.name)
      visit "/products/#{iphone.id}"
      expect(page).to have_text("This product record has been added to 2 notifications")
    end
  end

  def create_a_draft_notification
    visit "/notifications/create"

    expect(page).to have_current_path(/\/notifications\/\d{4}-\d{4}\/create/)
    click_link "Search for or add a product"

    click_button "Select", match: :first

    within_fieldset "Do you need to add another product?" do
      choose "No"
    end

    click_button "Continue"

    click_link "Add notification details"

    add_notification_details
  end

  def add_notification_details
    fill_in "Notification title", with: "Fake name"
    fill_in "Notification summary", with: "This is a fake summary"
    within_fieldset("Why are you creating the notification?") do
      choose "A product is unsafe or non-compliant"
    end
    click_button "Save and continue"
  end
end
