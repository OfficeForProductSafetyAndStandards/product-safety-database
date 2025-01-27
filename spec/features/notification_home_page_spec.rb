require "rails_helper"

RSpec.feature "Your notifications page", :with_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  let!(:user) { create(:user, :opss_user, :activated, has_viewed_introduction: true, roles: %w[notification_task_list_user]) }
  let!(:product_one) { create(:product_washing_machine, name: "MyBrand Washing Machine") }
  let!(:submitted_notification) { create(:notification, :with_business, products: [product_one], creator: user, state: "submitted", submitted_at: Time.zone.now) }

  before do
    sign_in(user)
  end

  scenario "displays draft and submitted notifications" do
    create_a_draft_notification

    visit "/notifications/your-notifications"

    expect(page).to have_content("Draft notifications")
    expect(page).to have_content("Fake name")
    expect(page).to have_content(product_one.name)

    expect(page).to have_content("Submitted notifications")
    expect(page).to have_content(submitted_notification.user_title)
    expect(page).to have_content(submitted_notification.updated_at.to_formatted_s(:govuk))
    expect(page).to have_content(submitted_notification.submitted_at.to_formatted_s(:govuk))
    expect(page).to have_link("Update notification", href: notification_path(submitted_notification))
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
