require "rails_helper"

RSpec.feature "Creating cases", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_keycloak_config do
  let(:hazard_type) { Rails.application.config.hazard_constants["hazard_type"].sample }

  before do
    sign_in as_user: create(:user, :activated, :opss_user)
    visit new_allegation_path
  end

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

  context "as an OPSS user" do
    scenario "able to create safety allegation from a consumer" do
      expect(page).to have_css("h1", text: "New allegation")

      choose "complainant_complainant_type_consumer"
      click_button "Continue"

      expect(page).to have_css("h1", text: "New allegation")

      enter_contact_details(contact_details)
      enter_allegation_details(allegation_details)

      expect_confirmation_banner("Allegation was successfully created")
    end

    scenario "able to add a product" do
      expect(page).to have_css("h1", text: "New allegation")
      choose "complainant_complainant_type_consumer"
      click_button "Continue"

      expect(page).to have_css("h1", text: "New allegation")

      enter_contact_details(contact_details)
      enter_allegation_details(allegation_details)

      expect_confirmation_banner("Allegation was successfully created")

      click_link "Products (0)"
      click_link "Add product"
      enter_product_details(product_details)


      expect_confirmation_banner("Product was successfully created.")

      click_link "Products (1)"

      expect_entered_product_details(product_details)
    end
  end
end
