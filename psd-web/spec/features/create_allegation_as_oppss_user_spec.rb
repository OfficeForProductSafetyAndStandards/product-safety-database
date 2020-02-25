require "rails_helper"

RSpec.feature "Creating cases", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_keycloak_config do
  let(:hazard_type) { Rails.application.config.hazard_constants["hazard_type"].sample }

  before { sign_in as_user: create(:user, :activated, :opss_user) }

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

  context "opss user" do
    scenario "able to create safety allegation as consumer" do
      visit new_allegation_path
      choose "complainant_complainant_type_consumer"
      click_button "Continue"

      expect(page).to have_css("h1", text: "New allegation")

      enter_contact_details(contact_name: contact_details[:contact_name], contact_email: contact_details[:contact_email], contact_phone: contact_details[:contact_phone])
      enter_allegation_details(allegation_description: allegation_details[:allegation_description], allegation_product_category: allegation_details[:category], allegation_hazard_type: allegation_details[:allegation_hazard_type])

      expect_confirmation_banner("Allegation was successfully created")
    end

    scenario "able to add a product" do
      visit new_allegation_path
      choose "complainant_complainant_type_consumer"
      click_button "Continue"

      expect(page).to have_css("h1", text: "New allegation")

      enter_contact_details(contact_name: contact_details[:contact_name], contact_email: contact_details[:contact_email], contact_phone: contact_details[:contact_phone])
      enter_allegation_details(allegation_description: allegation_details[:allegation_description], allegation_product_category: allegation_details[:category], allegation_hazard_type: allegation_details[:allegation_hazard_type])

      expect_confirmation_banner("Allegation was successfully created")

      click_link "Products (0)"
      click_link "Add product"
      enter_product_details(product_category: product_details[:category], product_origin: product_details[:country_of_origin], product_type: product_details[:type], product_name: product_details[:name], barcode: product_details[:barcode], webpage: product_details[:webpage], product_description: product_details[:description])

      expect_confirmation_banner("Product was successfully created.")

      click_link "Products (1)"

      expect_entered_product_details(product_category: product_details[:category], product_origin: product_details[:country_of_origin], product_type: product_details[:type], product_name: product_details[:name], barcode: product_details[:barcode], webpage: product_details[:webpage], product_description: product_details[:description])
    end
  end
end
