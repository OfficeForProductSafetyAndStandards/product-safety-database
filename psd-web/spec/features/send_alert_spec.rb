require "rails_helper"

RSpec.feature "Sending a product safety alert", :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_keycloak_config, type: :feature do
  let(:user) { create(:user, :activated, :opss_user) }
  let(:investigation) { create(:allegation) }

  before do
    create(:user, :activated)
    create(:user, :inactive)
    sign_in(as_user: user)

    # Don't need to generate preview for these tests. govuk_notify_rails throws an exception of no valid Notify key provided
    allow(Notifications::Client).to receive(:new).and_return(nil)
    allow(NotificationsClient.instance).to receive(:generate_template_preview).and_return(OpenStruct.new(html: nil))
  end

  scenario "shows the number of recipients the alert will be sent to, including active users only" do
    visit investigation_path(investigation)

    click_link "Add activity"

    choose "Send email alert about this case"
    click_button "Continue"

    click_link "Compose new alert"

    fill_in "Alert subject", with: "test"
    fill_in "Alert summary", with: "test"
    click_button "Preview alert"

    expect(page.text).to match(/All users \(\d+ people\)/)
    expect(page.text.match(/All users \((\d+) people\)/).captures.first).to eq("2")
  end
end
