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

  let(:user) { create(:user, :activated, :opss_user) }
  let(:other_user_same_team) { create(:user, :activated, organisation: user.organisation, team: user.team) }
  let(:other_user_different_org) { create(:user, :activated) }

  context "when logged in as an OPSS user" do
    before { sign_in(user) }

    scenario "is able to report an enquiry" do
      visit "/cases"

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

      expect_details_on_summary_page
      expect_protected_details_on_summary_page(contact_details)

      click_on "Activity"
      expect_details_on_activity_page(contact_details, enquiry_details)

      # Test that another user in a different organisation cannot see consumer info
      sign_out

      sign_in(other_user_different_org)

      investigation = Investigation.last

      visit "/cases/#{investigation.pretty_id}"

      expect_details_on_summary_page
      expect_protected_details_not_on_summary_page(contact_details)

      click_on "Activity"

      expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
      expect_case_activity_page_to_show_restricted_information(enquiry_details)

      # Test that another user in the same team can see consumer info
      sign_out

      sign_in(other_user_same_team)

      visit "/cases/#{investigation.pretty_id}"

      expect_details_on_summary_page
      expect_protected_details_on_summary_page(contact_details)

      click_on "Activity"

      expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
      expect_details_on_activity_page(contact_details, enquiry_details)
    end

    context "with enquiry date in the future" do
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

  def expect_details_on_summary_page
    expect(page.find("dt", text: "Source type")).to have_sibling("dd", text: "Consumer")
    expect(page.find("dt", text: "Coronavirus related"))
      .to have_sibling("dd", text: "Coronavirus related case")
  end

  def expect_protected_details_on_summary_page(contact_name:, contact_email:, contact_phone:)
    expect(page).to have_css("p", text: contact_name)
    expect(page).to have_css("p", text: contact_email)
    expect(page).to have_css("p", text: contact_phone)
  end

  def expect_protected_details_not_on_summary_page(contact_name:, contact_email:, contact_phone:)
    expect(page).not_to have_css("p", text: contact_name)
    expect(page).not_to have_css("p", text: contact_email)
    expect(page).not_to have_css("p", text: contact_phone)
  end

  def expect_details_on_activity_page(contact, enquiry)
    within ".govuk-list" do
      expect(page).to have_css("h3",           text: "Enquiry logged: #{enquiry.fetch(:enquiry_title)}")
      expect(page).to have_css("p",            text: "Case is related to the coronavirus outbreak.")
      expect(page).to have_css("p",            text: enquiry.fetch(:enquiry_description))
      expect(page).to have_css("p",            text: "Attachment: testImage.png")
      expect(page).to have_css("p.govuk-body", text: /Name: #{Regexp.escape(contact.fetch(:contact_name))}/)
      expect(page).to have_css("p.govuk-body", text: /Email address: #{Regexp.escape(contact.fetch(:contact_email))}/)
      expect(page).to have_css("p.govuk-body", text: /Phone number: #{Regexp.escape(contact.fetch(:contact_phone))}/)
      expect(page).to have_link("View attachment", href: /^.*testImage\.png$/)
    end
  end

  def expect_case_activity_page_to_show_restricted_information(enquiry)
    within ".govuk-list" do
      expect(page).to have_css("h3", text: "Enquiry logged: #{enquiry.fetch(:enquiry_title)}")
      expect(page).to have_css("p", text: "Case is related to the coronavirus outbreak.")
      expect(page).to have_css("p", text: enquiry.fetch(:enquiry_description))
      expect(page).to have_css("p", text: "Attachment: testImage.png")
      expect(page).to have_link("View attachment", href: /^.*testImage\.png$/)

      expect(page).to have_text("Restricted access")
      expect(page).to have_text("Consumer contact details hidden to comply with GDPR legislation. Contact test organisation, who created this activity, to obtain these details if required.")

      expect(page).not_to have_text("Name")
      expect(page).not_to have_text("Email address")
      expect(page).not_to have_text("Phone number")
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
