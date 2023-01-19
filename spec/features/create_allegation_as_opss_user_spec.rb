require "rails_helper"

RSpec.feature "Creating cases", :with_stubbed_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_product_form_helper do
  let(:hazard_type) { Rails.application.config.hazard_constants["hazard_type"].sample }
  let(:contact_details) do
    {
      contact_name: Faker::Name.name,
      contact_email: Faker::Internet.safe_email,
      contact_phone: Faker::PhoneNumber.phone_number,
    }
  end
  let(:allegation_details) do
    {
      description: Faker::Lorem.paragraph,
      hazard_type:,
      category: Rails.application.config.product_constants["product_category"].sample,
      file: Rails.root.join("test/fixtures/files/testImage.png")
    }
  end
  let(:team) { create(:team) }
  let(:user) { create(:user, :activated, :opss_user, team:) }
  let(:other_user_same_team) { create(:user, :activated, organisation: user.organisation, team: user.team) }
  let(:other_user_different_org) { create(:user, :activated) }

  context "when logged in as an OPSS user" do
    before { sign_in(user) }

    scenario "able to create safety allegation from a consumer and optionally add a product" do
      visit "/cases"

      click_link "Create a case"

      expect_page_to_have_h1("Create new")
      choose "Product safety allegation"
      click_button "Continue"

      expect_to_be_on_allegation_complainant_page
      choose "complainant_complainant_type_consumer"
      click_button "Continue"

      expect_to_be_on_allegation_complainant_details_page
      enter_contact_details(**contact_details)

      expect_to_be_on_allegation_details_page
      click_button "Create allegation"

      expect_to_be_on_allegation_details_page

      errors_list = page.find(".govuk-error-summary__list").all("li")
      expect(errors_list[0].text).to eq "Description cannot be blank"
      expect(errors_list[1].text).to eq "Enter a valid product category"
      expect(errors_list[2].text).to eq "Enter the primary hazard"

      enter_allegation_details(**allegation_details)

      expect_confirmation_banner("Allegation was successfully created")

      expect_page_to_have_h1("Case")

      investigation = Investigation.last.decorate
      expect(delivered_emails.last.personalization).to eq({
        name: user.name,
        case_title: investigation.decorate.title,
        case_type: "allegation",
        capitalized_case_type: "Allegation",
        case_id: investigation.pretty_id,
        investigation_url: investigation_url(investigation)
      })
      expect(delivered_emails.last.template).to eq "b5457546-9633-4a9c-a844-b61f2e818c24"

      expect_details_on_summary_page
      expect_protected_details_on_summary_page(**contact_details)

      # TODO: Test linking an existing product when this feature is introduced

      click_link "Activity"
      expect_details_on_activity_page(contact_details, allegation_details)

      # Test that another user in a different organisation cannot see consumer info
      sign_out

      sign_in(other_user_different_org)

      investigation = Investigation.last

      visit "/cases/#{investigation.pretty_id}"

      expect_details_on_summary_page
      expect_protected_details_not_on_summary_page(**contact_details)

      click_link "Activity"

      expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
      expect_case_activity_page_to_show_restricted_information(allegation_details)

      # Test that another user in the same team can see consumer info
      sign_out

      sign_in(other_user_same_team)

      visit "/cases/#{investigation.pretty_id}"

      expect_details_on_summary_page
      expect_protected_details_on_summary_page(**contact_details)

      click_link "Activity"

      expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
      expect_details_on_activity_page(contact_details, allegation_details)
    end
  end

  def enter_allegation_details(description:, hazard_type:, category:, file:)
    fill_in "allegation_description", with: description
    select category, from: "allegation_product_category"
    select hazard_type, from: "allegation_hazard_type"
    attach_file "allegation_attachment_file", file
    click_button "Create allegation"
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

  def expect_details_on_activity_page(contact, allegation)
    expect(page).to have_text("Product category: #{allegation.fetch(:category)}")
    expect(page).to have_text("Hazard type: #{allegation.fetch(:hazard_type)}")
    expect(page).to have_text(allegation.fetch(:description))
    expect(page).to have_text("Name: #{contact.fetch(:contact_name)}")
    expect(page).to have_text("Type: Consumer")
    expect(page).to have_text("Email address: #{contact.fetch(:contact_email)}")
    expect(page).to have_text("Phone number: #{contact.fetch(:contact_phone)}")
  end

  def expect_case_activity_page_to_show_restricted_information(allegation)
    expect(page).to have_text("Product category: #{allegation.fetch(:category)}")
    expect(page).to have_text("Hazard type: #{allegation.fetch(:hazard_type)}")
    expect(page).to have_text(allegation.fetch(:description))

    expect(page).to have_css("p", text: "Only teams added to the case can view allegation contact details")

    expect(page).not_to have_text("Name")
    expect(page).not_to have_text("Email address")
    expect(page).not_to have_text("Phone number")
  end
end
