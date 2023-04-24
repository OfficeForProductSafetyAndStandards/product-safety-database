require "rails_helper"

RSpec.feature "Reporting enquiries", :with_stubbed_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:date) { Faker::Date.backward(days: 14) }
  let(:received_type) { "enquiry_received_type_email" }
  let(:other_received_type) { Faker::Hipster.word }
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
      file: Rails.root.join("test/fixtures/files/testImage.png"),
    }
  end
  let(:blank_enquiry_details) do
    {
      enquiry_description: nil,
      enquiry_title: nil,
      file: nil,
    }
  end

  let(:team) { create(:team) }
  let(:user) { create(:user, :activated, :opss_user, team:) }
  let(:other_user_same_team) { create(:user, :activated, organisation: user.organisation, team: user.team) }
  let(:other_user_different_org) { create(:user, :activated) }

  context "when logged in as an OPSS user" do
    before { sign_in(user) }

    scenario "is able to report an enquiry" do
      visit "/cases/new"

      choose "type_enquiry"
      click_button "Continue"

      expect_to_be_on_about_enquiry_page

      check_invalid_date
      check_the_other_received_type_field_has_retained_its_value

      fill_in_when_and_how_was_it_received(received_type:, day: date.day, month: date.month, year: date.year)
      click_button "Continue"

      expect_to_be_on_complainant_page
      choose "complainant_complainant_type_consumer"
      click_button "Continue"

      expect_to_be_on_complainant_details_page
      enter_contact_details(**contact_details)

      expect_to_be_on_enquiry_details_page

      check_cannot_be_blank_errors

      fill_in_new_enquiry_details(with: enquiry_details)
      click_button "Create enquiry"

      expect_confirmation_banner("Enquiry was successfully created.")

      expect_page_to_have_h1("Case")

      expect_details_on_summary_page
      expect_protected_details_on_summary_page(**contact_details)

      click_on "Activity"
      expect_details_on_activity_page(contact_details, enquiry_details)

      # Test that another user in a different organisation cannot see consumer info
      sign_out

      sign_in(other_user_different_org)

      investigation = Investigation.last

      visit "/cases/#{investigation.pretty_id}"

      expect_details_on_summary_page
      expect_protected_details_not_on_summary_page(**contact_details)

      click_on "Activity"

      expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
      expect_case_activity_page_to_show_restricted_information(enquiry_details)

      # Test that another user in the same team can see consumer info
      sign_out

      sign_in(other_user_same_team)

      visit "/cases/#{investigation.pretty_id}"

      expect_details_on_summary_page
      expect_protected_details_on_summary_page(**contact_details)

      click_on "Activity"

      expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
      expect_details_on_activity_page(contact_details, enquiry_details)

      investigation = Investigation.last

      expect(delivered_emails.last.personalization).to eq({
        name: user.name,
        case_title: investigation.user_title,
        case_type: "enquiry",
        capitalized_case_type: "Enquiry",
        case_id: investigation.pretty_id,
        investigation_url: investigation_url(investigation)
      })
      expect(delivered_emails.last.template).to eq "b5457546-9633-4a9c-a844-b61f2e818c24"
    end

    context "with enquiry date in the future" do
      let(:date) { Faker::Date.forward(days: 14) }

      scenario "shows an error message" do
        visit "/enquiry/about_enquiry"
        expect_to_be_on_about_enquiry_page

        fill_in_when_and_how_was_it_received(received_type:, day: date.day, month: date.month, year: date.year)
        expect(page).to have_summary_error("Date enquiry received must be today or in the past")
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

        fill_in_when_and_how_was_it_received(received_type:, day: date.day, month: date.month, year: date.year)

        expect(page).to have_summary_error("Enter a received type \"Other\"")
      end
    end
  end

  def expect_details_on_summary_page
    expect(page.find("dt", text: "Source type")).to have_sibling("dd", text: "Consumer")
    expect(page.find("dt", text: "Notifying country")).to have_sibling("dd", text: "England")
  end

  def expect_protected_details_on_summary_page(contact_name:, contact_email:, contact_phone:)
    expect(page).to have_css("li", text: contact_name)
    expect(page).to have_css("li", text: contact_email)
    expect(page).to have_css("li", text: contact_phone)
  end

  def expect_protected_details_not_on_summary_page(contact_name:, contact_email:, contact_phone:)
    expect(page).not_to have_css("li", text: contact_name)
    expect(page).not_to have_css("li", text: contact_email)
    expect(page).not_to have_css("li", text: contact_phone)
  end

  def expect_details_on_activity_page(contact, enquiry)
    within ".timeline .govuk-list" do
      expect(page).to have_css("h3",           text: "Enquiry logged: #{enquiry.fetch(:enquiry_title)}")
      expect(page).to have_css("p",            text: enquiry.fetch(:enquiry_description))
      expect(page).to have_css("p.govuk-body", text: /Name: #{Regexp.escape(contact.fetch(:contact_name))}/)
      expect(page).to have_css("p.govuk-body", text: /Email address: #{Regexp.escape(contact.fetch(:contact_email))}/)
      expect(page).to have_css("p.govuk-body", text: /Phone number: #{Regexp.escape(contact.fetch(:contact_phone))}/)
    end
  end

  def expect_case_activity_page_to_show_restricted_information(enquiry)
    within ".timeline .govuk-list" do
      expect(page).to have_css("h3", text: "Enquiry logged: #{enquiry.fetch(:enquiry_title)}")
      expect(page).to have_css("p", text: enquiry.fetch(:enquiry_description))

      expect(page).to have_css("p", text: "Only teams added to the case can view enquiry contact details")

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

  def fill_in_when_and_how_was_it_received(received_type:, day:, month:, year:, other_received_type: nil)
    fill_in "Day", with: day
    fill_in "Month", with: month
    fill_in "Year", with: year
    choose received_type
    if received_type == "Other"
      fill_in "Other received type", with: other_received_type
    end
    click_button "Continue"
  end

  def fill_in_new_enquiry_details(with:)
    fill_in "enquiry_description", with: with[:enquiry_description]
    fill_in "enquiry_user_title", with: with[:enquiry_title]
    attach_file "enquiry_attachment_file", with[:file]
  end

  def check_invalid_date
    fill_in_when_and_how_was_it_received(received_type: "Other", day: "", month: "", year: date.year, other_received_type:)
    expect(page).to have_error_messages
    expect(page).to have_error_summary "Date enquiry received must include a day and month"
  end

  def check_cannot_be_blank_errors
    fill_in_new_enquiry_details(with: blank_enquiry_details)
    click_button "Create enquiry"

    expect(page).to have_error_messages
    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Description cannot be blank"
    expect(errors_list[1].text).to eq "User title cannot be blank"
  end

  def check_the_other_received_type_field_has_retained_its_value
    expect(page).to have_field("Other received type", with: other_received_type)
  end
end
