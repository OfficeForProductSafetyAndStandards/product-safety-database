require "rails_helper"

RSpec.feature "Update a business contact", :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user)     { create(:user, :activated, has_viewed_introduction: true) }
  let(:business) { create(:business, trading_name: "Acme Ltd") }
  let!(:contact) do
    create(:contact,
           business:,
           name: "Mr Smith",
           email: "smith@example.com",
           job_title: "Manager",
           phone_number: "01632 960 001")
  end

  scenario "Updating a contact" do
    sign_in user
    visit "/businesses/#{business.id}"

    expect_to_be_on_business_page(business_id: business.id, business_name: "Acme Ltd")

    click_link "Edit contact"
    expect_to_be_on_edit_business_contact_page(business_id: business.id, contact_id: contact.id)

    # Expect form to be pre-filled
    expect(page).to have_field("Name", with: "Mr Smith")
    expect(page).to have_field("Email", with: "smith@example.com")
    expect(page).to have_field("Telephone", with: "01632 960 001")
    expect(page).to have_field("Job title or role description", with: "Manager")

    # Change all the values
    fill_in "Name", with: "Mr Jones"
    fill_in "Email", with: "jones@example.com"
    fill_in "Telephone", with: "07700 900 982"
    fill_in "Job title or role description", with: "Director"

    click_button "Save"

    expect_to_be_on_business_page(business_id: business.id, business_name: "Acme Ltd")

    expect(page).to have_text("Mr Jones")
    expect(page).to have_text("jones@example.com")
    expect(page).to have_text("07700 900 982")
    expect(page).to have_text("Director")
  end
end
