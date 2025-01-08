require "rails_helper"

RSpec.feature "Deleting a business contact", :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
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

  scenario "Deleting a contact" do
    sign_in user

    visit "/businesses/#{business.id}"

    expect_to_be_on_business_page(business_id: business.id, business_name: "Acme Ltd")

    click_link "Remove contact"

    expect_to_be_on_remove_contact_for_a_business_page(business_id: business.id, contact_id: contact.id)
    expect(page).to have_text("Mr Smith")
    expect(page).to have_text("smith@example.com")
    expect(page).to have_text("Manager")
    expect(page).to have_text("01632 960 001")
    expect_to_have_business_breadcrumbs

    click_button "Remove contact"

    expect_to_be_on_business_page(business_id: business.id, business_name: "Acme Ltd")

    expect(page).not_to have_text("Mr Smith")
    expect(page).to have_text("No contacts")
  end
end
