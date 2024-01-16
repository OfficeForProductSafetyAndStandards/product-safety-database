RSpec.feature "Your Account", :with_stubbed_mailer, type: :feature do
  let(:user) do
    create(
      :user,
      :activated,
      :opss_user,
      name: "Joe Jones",
      email: "joe.jones@testing.gov.uk",
      mobile_number: "07700 900000",
      team: create(:team, name: "Standards and testing")
    )
  end

  scenario "Changing your name (with validation error)" do
    sign_in user

    visit "/"
    first(:link, "Your account").click

    expect_to_be_on_your_account_page

    expect(page).to have_summary_item(key: "Name", value: "Joe Jones")
    expect(page).to have_summary_item(key: "Email address", value: "joe.jones@testing.gov.uk")
    expect(page).to have_summary_item(key: "Mobile number", value: "07700 900000")

    click_link "Change name"

    expect_to_be_on_change_name_page
    expect_to_have_account_breadcrumbs

    fill_in "Full name", with: ""
    click_button "Save"

    expect(page).to have_text("Enter your full name")
    expect_to_have_account_breadcrumbs

    fill_in "Full name", with: "Joe Smith"
    click_button "Save"

    expect_to_be_on_your_account_page
    expect(page).to have_summary_item(key: "Name", value: "Joe Smith")
  end
end
