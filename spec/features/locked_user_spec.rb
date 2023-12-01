require "rails_helper"

RSpec.feature "Locked user", :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated) }

  before { delivered_emails.clear }

  scenario "locked while signed in" do
    sign_in(user)

    expect(page).to have_link "Sign out"

    user.lock_access!(reason: User.locked_reasons[:inactivity])
    expect(delivered_emails).to be_empty

    click_link "All notifications"

    expect_to_be_on_the_homepage
    expect(page).to have_link "Sign in to your account"

    sign_in(user)

    expect(page).to have_text("Your Product Safety Database account has now been locked")

    expect(delivered_emails.last.personalization[:name]).to eq(user.name)
    expect(delivered_emails.last.personalization[:unlock_user_url_token]).to be_present
    expect(delivered_emails.last.template).to eq NotifyMailer::TEMPLATES[:account_locked_inactive]
  end
end
