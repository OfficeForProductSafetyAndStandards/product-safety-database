require "rails_helper"

RSpec.feature "Locked user", :with_stubbed_mailer, :with_stubbed_elasticsearch, type: :feature do
  let(:user) { create(:user, :activated) }

  before { delivered_emails.clear }

  scenario "locked while signed in" do
    sign_in(user)

    expect(page).to have_link "Sign out"

    user.lock_access!(send_instructions: false)
    expect(delivered_emails).to be_empty

    click_link "All cases"

    expect_to_be_on_the_homepage
    expect(page).to have_link "Sign in to your account"

    sign_in(user)

    expect(page).to have_text("We’ve locked this account to protect its security.")
  end
end
