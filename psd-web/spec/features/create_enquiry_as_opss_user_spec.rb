require "rails_helper"

RSpec.feature "Reporting enquiries", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer do
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

  context "when logged in as an OPSS user" do
    before { sign_in(create(:user, :activated, :opss_user)) }

    scenario "is able to report an enquiry" do
      click_link "Open a new case"
      choose "type_enquiry"
      click_button "Continue"

      expect_to_be_on_coronavirus_page("/enquiry/coronavirus")
      click_button "Continue"

      expect_to_be_on_coronavirus_page("/enquiry/coronavirus")
      expect(page).to have_summary_error("Select whether or not the case is related to the coronavirus outbreak",)
      choose "Yes, it is (or could be)"
      click_button "Continue"

      expect_to_be_on_about_enquiry_page
      fill_in_when_and_how_was_it_received(received_type: received_type, day: date.day, month: date.month, year: date.year)
      click_button "Continue"

      expect_to_be_on_complainant_page
      choose "complainant_complainant_type_consumer"
      click_button "Continue"

      expect_to_be_on_complainant_details_page
      enter_contact_details(contact_details)

      expect_to_be_on_enquiry_details_page
      fill_in_new_enquiry_details(with: enquiry_details)
      click_button "Create enquiry"

      expect_confirmation_banner("Enquiry was successfully created.")

      expect_page_to_have_h1("Overview")

      expect_details_on_summary_page(contact_details)

      click_on "Activity"
      expect_details_on_activity_page(contact_details, enquiry_details)
    end

    context "with enquiry date as future" do
      let(:date) { Faker::Date.forward(days: 14) }

      scenario "shows an error message" do
        visit "/enquiry/about_enquiry"
        expect_to_be_on_about_enquiry_page

        fill_in_when_and_how_was_it_received(received_type: received_type, day: date.day, month: date.month, year: date.year)

        expect(page).to have_summary_error("Date received must be today or in the past")
      end
    end

    context "with enquiry received type empty" do
      scenario "shows an error message" do
        visit "/enquiry/about_enquiry"
        expect_to_be_on_about_enquiry_page

        fill_in_when_was_it_received(day: date.day, month: date.month, year: date.year)

        expect(page).to have_summary_error("Select a type")
      end
    end

    context "with received type other empty" do
      let(:received_type) { "enquiry_received_type_other" }

      scenario "shows an error message" do
        visit "/enquiry/about_enquiry"
        expect_to_be_on_about_enquiry_page

        fill_in_when_and_how_was_it_received(received_type: received_type, day: date.day, month: date.month, year: date.year)

        expect(page).to have_summary_error("Enter a received type \"Other\"")
      end
    end
  end

  def expect_to_be_on_about_enquiry_page
    expect(page).to have_current_path("/enquiry/about_enquiry")
    expect_page_to_have_h1("New enquiry")
  end

  def expect_to_be_on_complainant_page
    expect(page).to have_current_path("/enquiry/complainant")
    expect_page_to_have_h1("New enquiry")
  end

  def expect_to_be_on_complainant_details_page
    expect(page).to have_current_path("/enquiry/complainant_details")
    expect_page_to_have_h1("New enquiry")
    expect(page).to have_css(".govuk-fieldset__legend--m", text: "What are their contact details?")
  end

  def expect_to_be_on_enquiry_details_page
    expect(page).to have_current_path("/enquiry/enquiry_details")
    expect_page_to_have_h1("New enquiry")
    expect(page).to have_css(".govuk-fieldset__legend--m", text: "What is the enquiry?")
  end

  def expect_details_on_summary_page(contact_name:, contact_email:, contact_phone:)
    expect(page.find("dt", text: "Source type")).to have_sibling("dd", text: "Consumer")
    expect(page).to have_css("p", text: contact_name)
    expect(page).to have_css("p", text: contact_email)
    expect(page).to have_css("p", text: contact_phone)
    expect(page.find("dt", text: "Coronavirus related"))
      .to have_sibling("dd", text: "Coronavirus related case")
  end

  def expect_details_on_activity_page(contact, enquiry)
    within ".govuk-list" do
      expect(page).to have_css("h3", text: "Enquiry logged: #{enquiry.fetch(:enquiry_title)}")
      expect(page).to have_css("p", text: "Case is related to the coronavirus outbreak.")
      expect(page).to have_css("p", text: enquiry.fetch(:enquiry_description))
      expect(page).to have_css("p", text: "Attachment: testImage.png")
      expect(page).to have_css("p", text: "Name: #{contact.fetch(:contact_name)}")
      expect(page).to have_css("p", text: "Email address: #{contact.fetch(:contact_email)}")
      expect(page).to have_css("p", text: "Phone number: #{contact.fetch(:contact_phone)}")
      expect(page).to have_link("View attachment", href: /^.*testImage\.png$/)
    end
  end

  def fill_in_when_was_it_received(day:, month:, year:)
    fill_in "Day", with: day
    fill_in "Month", with: month
    fill_in "Year", with: year
    click_button "Continue"
  end

  def fill_in_when_and_how_was_it_received(received_type:, day:, month:, year:)
    fill_in "Day", with: day
    fill_in "Month", with: month
    fill_in "Year", with: year
    choose received_type
    click_button "Continue"
  end

  def fill_in_new_enquiry_details(with:)
    fill_in "enquiry_description", with: with[:enquiry_description]
    fill_in "enquiry_user_title", with: with[:enquiry_title]
    attach_file "enquiry_attachment_file", with[:file]
  end
end
