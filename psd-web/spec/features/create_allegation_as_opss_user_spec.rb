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

  context "when login as an OPSS user" do
    before do
      sign_in(create(:user, :activated, :opss_user))
    end

    scenario "able to create safety allegation from a consumer and optionally add a product" do
      visit "/cases"

      click_link "Open a new case"

      expect_page_to_have_h1("Create new")
      choose "Product safety allegation"
      click_button "Continue"

      expect_to_be_on_coronavirus_page
      choose "Yes, it is (or could be)"
      click_button "Continue"

      expect_page_to_have_h1("New allegation")
      choose "complainant_complainant_type_consumer"
      click_button "Continue"

      expect(page).to have_css(".govuk-fieldset__legend--m", text: "What are their contact details?")

      enter_contact_details(contact_details)

      expect(page).to have_css(".govuk-label--m", text: "What is being alleged?")

      enter_allegation_details(allegation_details)

      expect_confirmation_banner("Allegation was successfully created")
      expect(page.find("dt", text: "Coronavirus related")).to have_sibling("dd", text: "Coronavirus related case")

      click_link "Products (0)"
      click_link "Add product"

      expect(page).to have_css(".govuk-heading-m", text: "Add product")

      enter_product_details(product_details)

      expect_confirmation_banner("Product was successfully created.")

      click_link "Products (1)"

      expect_page_to_show_entered_product_details(product_details)
    end
  end

  def expect_to_be_on_coronavirus_page
    expect(page).to have_current_path("/allegation/coronavirus")
    expect(page).to have_selector("h1", text: "Is this case related to the coronavirus outbreak?")
    expect(page).to have_selector(".app-banner", text: "Coronavirus")
  end

  def enter_allegation_details(description:, hazard_type:, category:)
    fill_in "allegation_description", with: description
    select category, from: "allegation_product_category"
    select hazard_type, from: "allegation_hazard_type"
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
end
