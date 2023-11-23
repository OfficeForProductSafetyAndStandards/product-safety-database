require "rails_helper"

RSpec.feature "Notification task list", :with_stubbed_antivirus, :with_stubbed_mailer, :with_opensearch do
  let(:user) { create(:user, :opss_user, :activated, has_viewed_introduction: true, roles: %w[notification_task_list_user]) }

  before do
    sign_in(user)
  end

  scenario "Creating a notification using the task list" do
    visit "/notifications/create"

    expect(page).to have_current_path(/\/notifications\/\d{4}-\d{4}\/create/)
    expect(page).to have_content("Create a product safety notification")
  end
end
