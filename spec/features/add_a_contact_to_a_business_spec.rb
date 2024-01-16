RSpec.feature "Add a contact to a business", :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user)     { create(:user, :activated, has_viewed_introduction: true) }
  let(:business) { create(:business, trading_name: "Acme Ltd") }

  scenario "Adding a contact" do
    sign_in user
    visit "/businesses/#{business.id}"

    expect_to_be_on_business_page(business_id: business.id, business_name: "Acme Ltd")

    click_link "Add contact"
    expect_to_be_on_add_contact_to_a_business_page(business_id: business.id)
    expect_to_have_business_breadcrumbs

    fill_in "Name", with: "Mr Smith"
    fill_in "Email", with: "smith@example.com"
    fill_in "Telephone", with: "01632 960 001"
    fill_in "Job title or role description", with: "Manager"

    click_button "Save"

    expect_to_be_on_business_page(business_id: business.id, business_name: "Acme Ltd")

    expect(page).to have_text("Mr Smith")
    expect(page).to have_text("smith@example.com")
    expect(page).to have_text("01632 960 001")
    expect(page).to have_text("Manager")
  end
end
