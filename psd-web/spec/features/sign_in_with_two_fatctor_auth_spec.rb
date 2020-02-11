require "rails_helper"

RSpec.feature "Sign in with two factor auth", :with_elasticsearch, :with_stubbed_mailer do
  let(:user) { create(:user) }

  it "allows user to sign in" do
    visit root_path
    click_on "Sign in to your account"

    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: "password"
    click_on "Continue"

    expect(page).to have_css("h2")
  end
end
