require "rails_helper"
RSpec.feature "Reporting enquiries", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_keycloak_config do
  before { sign_in as_user: create(:user, :activated, :opss_user) }
  let(:date) { Faker::Date.backward(days: 14) }
  let(:received_type) { "enquiry_received_type_email" }



  let(:contact_details) do
    {
    contact_name: Faker::Name.name,
        contact_email: Faker::Internet.safe_email,
        contact_phone: Faker::PhoneNumber.phone_number,
    }
  end

  let(:enquiry_details) do
    {
      enquiry_description: Faker::Lorem.paragraph,
      enquiry_title: Faker::Name.name,
      file: Rails.root + "test/fixtures/files/testImage.png",
    }
  end

  context"as opss user"do
    scenario "able to report an enquiry"do
      click_link "Open a new case"
      choose "type_enquiry"
      click_button "Continue"
      fill_in_when_how_was_it_received
      choose "complainant_complainant_type_consumer"
      click_button "Continue"
      expect(page).to have_css("h1", text: "New enquiry")
      enter_contact_details(contact_name: contact_details[:contact_name], contact_email: contact_details[:contact_email], contact_phone: contact_details[:contact_phone])
      fill_in_new_enquiry_details(with: enquiry_details)
      click_button "Create enquiry"
      expect_confirmation_banner("Enquiry was successfully created.")
      validate_input_details_on_summary_page
    end
  end
  context "when enquiry date is future" do
    let(:date) { Faker::Date.forward(days: 14) }
    scenario "shows an error message" do
      visit new_investigation_enquiry_path
      fill_in_when_how_was_it_received
      expect(page).to have_css(".govuk-error-summary__list", text: "Date received must be today or in the past")
    end
  end
  context "when enquiry received type is empty" do
    scenario "shows an error message" do
      visit new_investigation_enquiry_path
      fill_in_when_was_it_received
      expect(page).to have_css(".govuk-error-summary__list", text: "Select a type")
    end
  end
  context "when received type other is left empty" do
    let(:received_type) { "enquiry_received_type_other" }
    scenario "shows an error message" do
      visit new_investigation_enquiry_path
      fill_in_when_how_was_it_received
      expect(page).to have_css(".govuk-error-summary__list", text: "Enter a received type \"Other\"")
    end
  end


  def validate_input_details_on_summary_page
    expect(page.find("dt", text: "Source type")).to have_sibling("dd", text: "Consumer")
    expect(page).to have_css("p", text: contact_details[:contact_name])
    expect(page).to have_css("p", text: contact_details[:contact_email])
    expect(page).to have_css("p", text: contact_details[:contact_phone])
  end

  def fill_in_when_was_it_received
    fill_in "Day", with: date.day if date
    fill_in "Month",   with: date.month if date
    fill_in "Year",    with: date.year  if date
    click_button "Continue"
  end

  def fill_in_when_how_was_it_received
    fill_in "Day", with: date.day if date
    fill_in "Month",   with: date.month if date
    fill_in "Year",    with: date.year  if date
    choose received_type
    click_button "Continue"
  end

  def fill_in_new_enquiry_details(with:)
    fill_in "enquiry_description", with: with[:enquiry_description]
    fill_in "enquiry_user_title", with: with[:enquiry_title]
    attach_file "enquiry_attachment_file", with[:file]
  end

  # def enter_contact_details(with:)
  #   expect(page).to have_css("h1", text: "New enquiry")
  #   fill_in "complainant[name]", with: with[:contact_name]
  #   fill_in "complainant_email_address", with: with[:contact_email]
  #   fill_in "complainant_phone_number", with: with[:contact_phone]
  #   click_button "Continue"
  # end
end
