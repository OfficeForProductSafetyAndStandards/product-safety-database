require "rails_helper"

RSpec.feature "Account administration", :with_stubbed_mailer, :with_stubbed_notify, type: :feature do
  let!(:user) { create(:user, roles: %w[support_portal]) }
  let!(:user_one) { create(:user) }
  let!(:user_two) { create(:user) }
  let!(:user_three) { create(:user, name: user_one.name) }

  before do
    configure_requests_for_support_domain

    user_one
    user_two
    user_three

    sign_in user
  end

  after do
    reset_domain_request_mocking
    Capybara.reset_sessions!
  end

  scenario "Searching for an account that exists" do
    expect(page).to have_h1("Dashboard")

    click_link "Account administration"
    click_link "Search for an account"

    expect(page).to have_h1("Search for an account")

    fill_in "Enter a search term", with: user_two.name
    click_on "Search"

    expect(page).to have_text(user_two.name)
    expect(page).to have_text(user_two.email)
    expect(page).to have_text(user_two.team.name)
    expect(page).not_to have_text(user_one.name)
    expect(page).not_to have_text(user_one.email)
    expect(page).not_to have_text(user_three.name)
    expect(page).not_to have_text(user_three.email)
  end

  scenario "Searching for an account that exists with multiple results" do
    expect(page).to have_h1("Dashboard")

    click_link "Account administration"
    click_link "Search for an account"

    expect(page).to have_h1("Search for an account")

    fill_in "Enter a search term", with: user_one.name
    click_on "Search"

    expect(page).to have_text(user_one.name)
    expect(page).to have_text(user_one.email)
    expect(page).to have_text(user_one.team.name)
    expect(page).to have_text(user_three.name)
    expect(page).to have_text(user_three.email)
    expect(page).to have_text(user_three.team.name)
    expect(page).not_to have_text(user_two.name)
    expect(page).not_to have_text(user_two.email)
  end

  scenario "Searching for a account that doesn't exist" do
    expect(page).to have_h1("Dashboard")

    click_link "Account administration"
    click_link "Search for an account"

    expect(page).to have_h1("Search for an account")

    fill_in "Enter a search term", with: "Random name"
    click_on "Search"

    expect(page).to have_text('There are no accounts for "Random name".')

    click_on "Clear search results"

    expect(page).to have_text("Enter a search term")
  end

  scenario "Searching for an empty string" do
    expect(page).to have_h1("Dashboard")

    click_link "Account administration"
    click_link "Search for an account"

    expect(page).to have_h1("Search for an account")

    click_on "Search"

    expect(page).to have_text(user_one.name)
    expect(page).to have_text(user_one.email)
    expect(page).to have_text(user_one.team.name)
    expect(page).to have_text(user_two.name)
    expect(page).to have_text(user_two.email)
    expect(page).to have_text(user_two.team.name)
    expect(page).to have_text(user_three.name)
    expect(page).to have_text(user_three.email)
    expect(page).to have_text(user_three.team.name)
  end

  scenario "Viewing account details" do
    visit "/account-admin/#{user_two.id}"

    expect(page).to have_h1(user_two.name)

    expect(page).to have_text(user_two.name)
    expect(page).to have_text(user_two.email)
    expect(page).to have_text(user_two.mobile_number)
    expect(page).to have_text(user_two.team.name)
    expect(page).to have_text("User is not a team admin")
    expect(page).to have_h2("Last login details")
  end

  scenario "Changing the name on an account" do
    existing_name = user_two.name

    visit "/account-admin/#{user_two.id}"

    expect(page).to have_h1(user_two.name)

    click_link "Change name"

    expect(page).to have_h1("Change account name")

    fill_in "Name", with: ""
    click_on "Save changes"

    expect(page).to have_link("Enter your full name", href: "#user-name-field-error")

    fill_in "Name", with: "This is a different name"
    click_on "Save changes"

    expect(page).to have_css("div.govuk-notification-banner", text: "The name has been updated from #{existing_name} to This is a different name.")
  end

  scenario "Changing the email on an account" do
    existing_email = user_three.email

    visit "/account-admin/#{user_three.id}"

    expect(page).to have_h1(user_three.name)

    click_link "Change email"

    expect(page).to have_h1("Change account email address")

    fill_in "Email", with: ""
    click_on "Save changes"

    expect(page).to have_link("Email cannot be blank", href: "#user-email-field-error")

    fill_in "Email", with: "something@something@example.com"
    click_on "Save changes"

    expect(page).to have_link("Email is invalid", href: "#user-email-field-error")

    fill_in "Email", with: "something@example.com"
    click_on "Save changes"

    expect(page).to have_css("div.govuk-notification-banner", text: "The email address has been updated from #{existing_email} to something@example.com.")
  end

  scenario "Changing the mobile number on an account" do
    existing_mobile_number = user_two.mobile_number

    visit "/account-admin/#{user_two.id}"

    expect(page).to have_h1(user_two.name)

    click_link "Change mobile number"

    expect(page).to have_h1("Change account mobile number")

    fill_in "Mobile number", with: ""
    click_on "Save changes"

    expect(page).to have_link("Enter your mobile number", href: "#user-mobile-number-field-error")

    fill_in "Mobile number", with: "01234567890"
    click_on "Save changes"

    expect(page).to have_css("div.govuk-notification-banner", text: "The mobile number has been updated from #{existing_mobile_number} to 01234567890.")
  end

  scenario "Changing the team admin role on an account" do
    visit "/account-admin/#{user_three.id}"

    expect(page).to have_h1(user_three.name)

    click_link "Change team admin role"

    expect(page).to have_h1("Change team admin role")

    check "Team admin?"
    click_on "Save changes"

    expect(page).to have_css("div.govuk-notification-banner", text: "The team admin role has been added.")

    click_link "Change team admin role"

    expect(page).to have_h1("Change team admin role")

    uncheck "Team admin?"
    click_on "Save changes"

    expect(page).to have_css("div.govuk-notification-banner", text: "The team admin role has been removed.")
  end

  scenario "Deleting an account", skip: "This is not how deleting an account seems to work." do
    visit "/account-admin/#{user.id}"

    expect(page).to have_h1(user.name)

    expect(page).to have_link("Delete account")
    click_link "Delete account"

    expect(page).to have_h1("Delete account for #{user_two.name}")
    click_link("Cancel")

    expect(page).not_to have_css("div.govuk-notification-banner", text: "The user account has been deleted.")

    expect(page).to have_link("Delete account")
    click_link "Delete account"

    expect(page).to have_h1("Delete account for #{user_two.name}")
    click_button("Confirm delete account")

    expect(page).to have_css("div.govuk-notification-banner", text: "The user account has been deleted.")
  end

  scenario "Inviting a new user" do
    expect(page).to have_h1("Dashboard")

    click_link "Account administration"
    click_link "Add a new account"

    expect(page).to have_h1("Add a new account")

    click_on "Send invitation"

    expect(page).to have_link("Enter an email address", href: "#invite-user-form-email-field-error")
    expect(page).to have_link("Select a team", href: "#invite-user-form-team-id-field-error")

    fill_in "Name", with: "Fake faker"
    fill_in "Email address", with: "fake@example.com"
    select Team.all.sample.name, from: "Team", match: :first

    click_on "Send invitation"

    expect(page).to have_text("New user account invitation has been sent.")
  end
end
