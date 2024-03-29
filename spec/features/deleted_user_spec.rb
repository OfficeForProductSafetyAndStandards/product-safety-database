require "rails_helper"

RSpec.feature "Deleted user", :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated) }

  scenario "deleted while signed in" do
    sign_in(user)

    expect(page).to have_link "Sign out"

    user.mark_as_deleted!

    click_link "Create a product safety notification"

    expect_to_be_on_the_homepage
    expect(page).to have_link "Sign in"

    sign_in(user)

    expect(page).to have_summary_error("Enter correct email address and password")
  end
end
