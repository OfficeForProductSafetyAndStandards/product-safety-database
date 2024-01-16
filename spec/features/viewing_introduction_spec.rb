RSpec.feature "Viewing the introduction", :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated, has_viewed_introduction: false) }

  scenario "Viewing the steps in order" do
    sign_in user

    visit "/introduction/overview"
    expect(page).to have_selector("h1", text: "Report, track and share product safety information")
    click_on "Continue"

    expect(page).to have_current_path("/introduction/report_products")
    click_on "Continue"

    expect(page).to have_current_path("/introduction/track_investigations")
    click_on "Continue"

    expect(page).to have_current_path("/introduction/share_data")
    click_on "Get started"

    expect(page).to have_content("Create a product safety notification")
    expect(page).to have_current_path("/")
  end

  scenario "Skipping the introduction" do
    sign_in user

    visit "/introduction/overview"
    click_on "Skip introduction"

    expect(page).to have_current_path("/")
  end

  scenario "Not being shown the introduction twice" do
    sign_in user

    visit "/introduction/overview"
    click_on "Continue"
    click_on "Continue"
    click_on "Continue"
    click_on "Get started"
    visit "/"
    expect(page).to have_current_path("/")
  end
end
