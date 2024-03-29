require "rails_helper"

RSpec.describe "Visibility of cookie banners", type: :feature do
  let(:cookie_banner_text) do
    "We use some essential cookies to make this service work.
We’d also like to use analytics cookies so we can understand how you use the service and make improvements."
  end

  scenario "when the user accepts analytics cookies and changes their mind" do
    visit("/")
    expect(page).to have_text(cookie_banner_text)

    click_button("Accept analytics cookies")
    expect(page).to have_text("You’ve accepted additional cookies.")

    click_button("Hide cookie message")
    expect(page).not_to have_text(cookie_banner_text)
    expect(page).not_to have_text("You’ve accepted additional cookies.")

    click_link("Cookies")
    expect(page).to have_checked_field("Yes")

    within("#new_cookie_form") do
      choose("No")
    end
    click_button("Save cookie settings")
    expect(page).to have_text("Your cookie settings were saved")
    expect(page).to have_checked_field("No")
  end
end
