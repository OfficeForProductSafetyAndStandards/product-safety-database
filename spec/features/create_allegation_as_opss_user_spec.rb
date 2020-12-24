require "rails_helper"

RSpec.feature "Creating cases", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_product_form_helper do
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
      description: Faker::Lorem.sentence,
      authenticity: Product.authenticities.keys.without("missing").sample,
      affected_units_status: "approx",
      has_markings: %w[Yes No Unknown].sample,
      markings: [Product::MARKINGS.sample]
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

      expect_page_to_have_h1("Overview")

      expect_details_on_summary_page
      expect_protected_details_on_summary_page(**contact_details)

      click_link "Products (0)"
      click_link "Add product"

      expect(page).to have_css(".govuk-heading-m", text: "Add product")

      enter_product_details(**product_details)

      expect_confirmation_banner("Product was successfully created.")

      click_link "Products (1)"

      expect_page_to_show_entered_product_details(**product_details.except(:affected_units_status))

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

  def enter_product_details(name:, barcode:, category:, type:, webpage:, country_of_origin:, description:, authenticity:, affected_units_status:, has_markings:, markings:)
    select category,                      from: "Product category"
    select country_of_origin,             from: "Country of origin"
    fill_in "Product subcategory", with: type
    within_fieldset("Is the product counterfeit?") { choose counterfeit_answer(authenticity) }

    within_fieldset("Does the product have UKCA, UKNI, or CE marking?") do
      choose has_markings
    end

    within_fieldset("Select product marking") do
      markings.each { |marking| check(marking) } if has_markings == "Yes"
    end

    within_fieldset("How many units are affected?") do
      choose affected_units_status_answer(affected_units_status)
      find("#approx_units").set(21)
    end
    fill_in "Product name",               with: name
    fill_in "Other product identifiers",  with: barcode
    fill_in "Webpage",                    with: webpage
    fill_in "Description of product",     with: description
    click_button "Save product"
  end

  def expect_page_to_show_entered_product_details(name:, barcode:, category:, type:, webpage:, country_of_origin:, description:, authenticity:, has_markings:, markings:)
    expected_markings = case has_markings
                        when "Yes" then markings.join(", ")
                        when "No" then "None"
                        when "Unknown" then "Unknown"
                        end

    expect(page.find("dt", text: "Product name")).to have_sibling("dd", text: name)
    expect(page.find("dt", text: "Product subcategory")).to have_sibling("dd", text: type)
    expect(page.find("dt", text: "Product authenticity")).to have_sibling("dd", text: I18n.t(authenticity, scope: Product.model_name.i18n_key))
    expect(page.find("dt", text: "Product marking")).to have_sibling("dd", text: expected_markings)
    expect(page.find("dt", text: "Category")).to have_sibling("dd", text: category)
    expect(page.find("dt", text: "Other product identifiers")).to have_sibling("dd", text: barcode)
    expect(page.find("dt", text: "Webpage")).to have_sibling("dd", text: webpage)
    expect(page.find("dt", text: "Country of origin")).to have_sibling("dd", text: country_of_origin)
    expect(page.find("dt", text: "Description")).to have_sibling("dd", text: description)
    expect(page.find("dt", text: "Units affected")).to have_sibling("dd", text: "21")
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
    expect(page).to have_text("Name: #{contact.fetch(:contact_name)}")
    expect(page).to have_text("Type: Consumer")
    expect(page).to have_text("Email address: #{contact.fetch(:contact_email)}")
    expect(page).to have_text("Phone number: #{contact.fetch(:contact_phone)}")
  end

  def expect_case_activity_page_to_show_restricted_information(allegation)
    expect(page).to have_text("Case is related to the coronavirus outbreak.")
    expect(page).to have_text("Product category: #{allegation.fetch(:category)}")
    expect(page).to have_text("Hazard type: #{allegation.fetch(:hazard_type)}")
    expect(page).to have_text(allegation.fetch(:description))

    expect(page).to have_css("p", text: "Only teams added to the case can view allegation contact details")

    expect(page).not_to have_text("Name")
    expect(page).not_to have_text("Email address")
    expect(page).not_to have_text("Phone number")
  end
end
