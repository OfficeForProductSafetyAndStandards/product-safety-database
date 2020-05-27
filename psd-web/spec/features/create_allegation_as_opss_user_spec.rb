require "rails_helper"

RSpec.feature "Creating cases", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer do
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
      hazard_type: hazard_type,
      category: Rails.application.config.product_constants["product_category"].sample,
      file: Rails.root + "test/fixtures/files/testImage.png"
    }
  end
  let(:product_details) do
    {
      name: Faker::Lorem.sentence,
      barcode: Faker::Number.number(digits: 10),
      category: Rails.application.config.product_constants["product_category"].sample,
      type: Faker::Appliance.equipment,
      webpage: Faker::Internet.url,
      country_of_origin: Country.all.sample.first,
      description: Faker::Lorem.sentence
    }
  end

  let(:user) { create(:user, :activated, :opss_user) }
  let(:other_user_same_team) { create(:user, :activated, organisation: user.organisation, team: user.team) }
  let(:other_user_different_org) { create(:user, :activated) }

  context "when logged in as an OPSS user" do
    before { sign_in(user) }

    scenario "able to create safety allegation from a consumer and optionally add a product" do
      visit "/cases"

      click_link "Open a new case"

      expect_page_to_have_h1("Create new")
      choose "Product safety allegation"
      click_button "Continue"

      expect_to_be_on_coronavirus_page("/allegation/coronavirus")
      click_button "Continue"

      expect_to_be_on_coronavirus_page("/allegation/coronavirus")
      expect(page).to have_summary_error("Select whether or not the case is related to the coronavirus outbreak")
      choose "Yes, it is (or could be)"
      click_button "Continue"

      expect_to_be_on_allegation_complainant_page
      choose "complainant_complainant_type_consumer"
      click_button "Continue"

      expect_to_be_on_allegation_complainant_details_page
      enter_contact_details(contact_details)

      expect_to_be_on_allegation_details_page
      click_button "Create allegation"

      expect_to_be_on_allegation_details_page
      expect(page).to have_summary_error("Description cannot be blank")
      expect(page).to have_summary_error("Enter the primary hazard")
      expect(page).to have_summary_error("Enter a valid product category")

      enter_allegation_details(allegation_details)

      expect_confirmation_banner("Allegation was successfully created")

      expect_page_to_have_h1("Overview")

      expect_details_on_summary_page
      expect_protected_details_on_summary_page(contact_details)

      click_link "Products (0)"
      click_link "Add product"

      expect(page).to have_css(".govuk-heading-m", text: "Add product")

      enter_product_details(product_details)

      expect_confirmation_banner("Product was successfully created.")

      click_link "Products (1)"

      expect_page_to_show_entered_product_details(product_details)

      click_link "Activity"
      expect_details_on_activity_page(contact_details, allegation_details)

      # Test that another user in a different organisation cannot see consumer info
      sign_out

      sign_in(other_user_different_org)

      investigation = Investigation.last

      visit "/cases/#{investigation.pretty_id}"

      expect_details_on_summary_page
      expect_protected_details_not_on_summary_page(contact_details)

      click_link "Activity"

      expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
      expect_case_activity_page_to_show_restricted_information(allegation_details)

      # Test that another user in the same team can see consumer info
      sign_out

      sign_in(other_user_same_team)

      visit "/cases/#{investigation.pretty_id}"

      expect_details_on_summary_page
      expect_protected_details_on_summary_page(contact_details)

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

  def enter_product_details(name:, barcode:, category:, type:, webpage:, country_of_origin:, description:)
    select category, from: "Product category"
    select country_of_origin, from: "Country of origin"
    fill_in "Product type",               with: type
    fill_in "Product name",               with: name
    fill_in "Barcode or serial number",   with: barcode
    fill_in "Webpage",                    with: webpage
    fill_in "Description of product",     with: description
    click_button "Save product"
  end

  def expect_page_to_show_entered_product_details(name:, barcode:, category:, type:, webpage:, country_of_origin:, description:)
    expect(page.find("dt", text: "Product name")).to have_sibling("dd", text: name)
    expect(page.find("dt", text: "Product type")).to have_sibling("dd", text: type)
    expect(page.find("dt", text: "Category")).to have_sibling("dd", text: category)
    expect(page.find("dt", text: "Barcode or serial number")).to have_sibling("dd", text: barcode)
    expect(page.find("dt", text: "Webpage")).to have_sibling("dd", text: webpage)
    expect(page.find("dt", text: "Country of origin")).to have_sibling("dd", text: country_of_origin)
    expect(page.find("dt", text: "Description")).to have_sibling("dd", text: description)
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

  def expect_details_on_activity_page(contact, allegation)
    expect(page).to have_text("Case is related to the coronavirus outbreak.")
    expect(page).to have_text("Product category: #{allegation.fetch(:category)}")
    expect(page).to have_text("Hazard type: #{allegation.fetch(:hazard_type)}")
    expect(page).to have_text(allegation.fetch(:description))
    expect(page).to have_text("Attachment: testImage.png")
    expect(page).to have_text("Name: #{contact.fetch(:contact_name)}")
    expect(page).to have_text("Type: Consumer")
    expect(page).to have_text("Email address: #{contact.fetch(:contact_email)}")
    expect(page).to have_text("Phone number: #{contact.fetch(:contact_phone)}")
    expect(page).to have_link("View attachment", href: /^.*testImage\.png$/)
  end

  def expect_case_activity_page_to_show_restricted_information(allegation)
    expect(page).to have_text("Case is related to the coronavirus outbreak.")
    expect(page).to have_text("Product category: #{allegation.fetch(:category)}")
    expect(page).to have_text("Hazard type: #{allegation.fetch(:hazard_type)}")
    expect(page).to have_text(allegation.fetch(:description))
    expect(page).to have_text("Attachment: testImage.png")
    expect(page).to have_link("View attachment", href: /^.*testImage\.png$/)

    expect(page).to have_text("Restricted access")
    expect(page).to have_text("Consumer contact details hidden to comply with GDPR legislation. Contact test organisation, who created this activity, to obtain these details if required.")

    expect(page).not_to have_text("Name")
    expect(page).not_to have_text("Email address")
    expect(page).not_to have_text("Phone number")
  end
end
