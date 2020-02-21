require "rails_helper"

RSpec.feature "Creating cases", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_keycloak_config do
  before { sign_in as_user: create(:user, :activated, :opss_user) }
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
      allegation_description: Faker::Lorem.paragraph,
      allegation_hazard_type: hazard_type,
      category: Rails.application.config.product_constants["product_category"].sample,
      file: Rails.root + "test/fixtures/files/testImage.png",
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

  context"opss user"do
    scenario "able to create safety allegation as consumer"do
      visit new_allegation_path
      choose "complainant_complainant_type_consumer"
      click_button "Continue"
      enter_contact_details(with: contact_details)
      enter_allegation_details(with: allegation_details)
      expect_confirmation_banner("Allegation was successfully created")
    end
    scenario "able to add a product" do
      visit new_allegation_path
      choose "complainant_complainant_type_consumer"
      click_button "Continue"
      enter_contact_details(with: contact_details)
      enter_allegation_details(with: allegation_details)
      expect_confirmation_banner("Allegation was successfully created")
      click_link "Products (0)"
      click_link "Add product"
      enter_product_details(with: product_details)
      expect_confirmation_banner("Product was successfully created.")
    end
  end

  def enter_contact_details(with:)
    expect(page).to have_css("h1", text: "New allegation")
    fill_in "complainant[name]", with: with[:contact_name]
    fill_in "complainant_email_address", with: with[:contact_email]
    fill_in "complainant_phone_number", with: with[:contact_phone]
    click_button "Continue"
  end

  def enter_allegation_details(with:)
    expect(page).to have_css("h1", text: "New allegation")
    fill_in "allegation_description", with: with[:allegation_description]
    select with[:category], from: "allegation_product_category"
    select with[:allegation_hazard_type], from: "allegation_hazard_type"
    click_button "Create allegation"
  end

  def enter_product_details(with:)
    select with[:category], from: "Product category"
    select with[:country_of_origin], from: "Country of origin"
    fill_in "Product type",               with: with[:type]
    fill_in "Product name",               with: with[:name]
    fill_in "Barcode or serial number",   with: with[:barcode]
    fill_in "Webpage",                    with: with[:webpage]
    fill_in "Description of product",     with: with[:description]
    click_button "Save product"
  end
end
