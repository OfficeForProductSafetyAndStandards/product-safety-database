require "rails_helper"

RSpec.describe "Reporting a product", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_keycloak_config do
  before { sign_in as_user: create(:user, :activated, :opss_user) }

  let(:reference_number) { Faker::Number.number(digits: 10) }
  let(:hazard_type) { Rails.application.config.hazard_constants["hazard_type"].sample }
  let(:hazard_description) { Faker::Lorem.paragraph }
  let(:non_compliance_details) { Faker::Lorem.paragraph }
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

  let(:business_details) do
    business = -> {
      {
        trading_name: Faker::Restaurant.name,
        legal_name: Faker::Restaurant.name,
        company_number: Faker::Number.number(digits: 8),
        address_1: Faker::Address.street_address,
        address_2: Faker::Address.secondary_address,
        town: Faker::Address.city,
        county: Faker::Address.state,
        postcode: Faker::Address.postcode,
        country: Country.all.sample.first,
        contact_name: Faker::Name.name,
        contact_email: Faker::Internet.safe_email,
        contact_phone: Faker::PhoneNumber.phone_number,
        contact_job_title: Faker::Lorem.sentence,
      }
    }
    {
      retailer: business.call,
      advertiser: business.call
    }
  end

  let(:corrective_actions) {
    action = -> {
      {
        summary: Faker::Lorem.sentence,
        date: Faker::Date.backward(days: 14),
        legislation: Rails.application.config.legislation_constants["legislation"].sample,
        details: Faker::Lorem.sentence,
        file: Rails.root + "test/fixtures/files/old_risk_assessment.txt",
        file_description: Faker::Lorem.paragraph,
        measure_type: CorrectiveAction::MEASURE_TYPES.sample,
        duration: CorrectiveAction::DURATION_TYPES.sample,
        geographic_scope: Rails.application.config.corrective_action_constants["geographic_scope"].sample,
      }
    }

    [
      action.call,
      action.call
    ]
  }

  let(:test_results) do
    [
      {
        legislation: Rails.application.config.legislation_constants["legislation"].sample,
        date: Faker::Date.backward(days: 14),
        result: %w[Pass Fail].sample,
        details: Faker::Lorem.sentence,
        file: Rails.root + "test/fixtures/files/test_result.txt"
      }
    ]
  end

  let(:risk_assessments) {
    assessment = -> {
      {
        file: Rails.root + "test/fixtures/files/new_risk_assessment.txt",
        title: Faker::Lorem.sentence,
        description: Faker::Lorem.paragraph
      }
    }

    [
      assessment.call,
      assessment.call
    ]
  }

  it "as a non-OPSS user" do
    visit new_ts_investigation_path

    expect_to_be_on_product_page
    fill_in_product_page(with: product_details)

    expect_to_be_on_why_reporting_page
    fill_in_why_reporting_page

    expect_to_be_on_supply_chain_page
    fill_in_supply_chain_page

    expect_to_be_on_business_details_page("Retailer")
    fill_in_business_details_page(with: business_details[:retailer])

    expect_to_be_on_business_details_page("Distributor")
    skip_page

    expect_to_be_on_business_details_page("Advertiser")
    fill_in_business_details_page(with: business_details[:advertiser])

    expect_to_be_on_corrective_action_taken_page
    fill_in_corrective_action_taken_page

    expect_to_be_on_record_corrective_action_page

    corrective_actions.each do |action|
      fill_in_record_corrective_action_page(with: action)
      expect_to_be_on_record_corrective_action_page
    end

    skip_page

    expect_to_be_on_other_information_page
    fill_in_other_information_page

    expect_to_be_on_test_result_details_page

    test_results.each do |result|
      fill_in_test_results_page(with: result)
      expect_to_be_on_test_result_details_page
    end

    skip_page

    expect_to_be_on_risk_assessment_details_page

    risk_assessments.each do |assessment|
      fill_in_risk_assessment_details_page(with: assessment)
      expect_to_be_on_risk_assessment_details_page
    end

    skip_page

    fill_in_reference_number_page(reference_number)

    expect_to_be_on_case_created_page

    click_link "View case"

    expect_case_details_page_to_show_entered_information

    click_link "Products (1)"

    expect_case_products_page_to_show(info: product_details)

    click_link "Businesses (2)"

    expect_case_businesses_page_to_show(label: "Retailer", business: business_details[:retailer])
    expect_case_businesses_page_to_show(label: "Advertiser", business: business_details[:advertiser])

    click_link "Attachments (5)"

    corrective_actions.each { |action| expect_case_attachments_page_to_show(file_description: action[:summary]) }
    test_results.each { |test| expect_case_attachments_page_to_show(file_description: "#{test[:result]}ed test") }
    risk_assessments.each { |assessment| expect_case_attachments_page_to_show(file_description: assessment[:title]) }

    click_link "Activity"

    corrective_actions.each { |action| expect_case_activity_page_to_show_corrective_action(action) }
    test_results.each { |test| expect_case_activity_page_to_show_test_result(test) }
    risk_assessments.each { |assessment| expect_case_activity_page_to_show_risk_assessment(assessment) }
  end

  def expect_no_error_messages
    expect(page).not_to have_error_messages
  end

  def expect_to_be_on_product_page
    expect(page).to have_current_path("/ts_investigation/product")
    expect(page).to have_selector("h1", text: "What product are you reporting?")
    expect_no_error_messages
  end

  def expect_to_be_on_why_reporting_page
    expect(page).to have_current_path("/ts_investigation/why_reporting")
    expect(page).to have_selector("h1", text: "Why are you reporting this product?")
    expect_no_error_messages
  end

  def expect_to_be_on_supply_chain_page
    expect(page).to have_current_path("/ts_investigation/which_businesses")
    expect(page).to have_selector("h1", text: "Supply chain information")
    expect_no_error_messages
  end

  def expect_to_be_on_business_details_page(title)
    expect(page).to have_current_path("/ts_investigation/business")
    expect(page).to have_selector("h1", text: "#{title} details")
    expect_no_error_messages
  end

  def expect_to_be_on_corrective_action_taken_page
    expect(page).to have_current_path("/ts_investigation/has_corrective_action")
    expect(page).to have_selector("h1", text: "Has any corrective action been agreed or taken?")
    expect_no_error_messages
  end

  def expect_to_be_on_record_corrective_action_page
    expect(page).to have_current_path("/ts_investigation/corrective_action")
    expect(page).to have_selector("h1", text: "Record corrective action")
    expect_no_error_messages
  end

  def expect_to_be_on_other_information_page
    expect(page).to have_current_path("/ts_investigation/other_information")
    expect(page).to have_selector("h1", text: "Other information and files")
    expect_no_error_messages
  end

  def expect_to_be_on_test_result_details_page
    expect(page).to have_current_path("/ts_investigation/test_results")
    expect(page).to have_selector("h1", text: "Test result details")
    expect_no_error_messages
  end

  def expect_to_be_on_risk_assessment_details_page
    expect(page).to have_current_path("/ts_investigation/risk_assessments")
    expect(page).to have_selector("h1", text: "Risk assessment details")
    expect_no_error_messages
  end

  def expect_to_be_on_reference_number_page
    expect(page).to have_current_path("/ts_investigation/reference_number")
    expect(page).to have_selector("h1", text: "Add your own reference number")
    expect_no_error_messages
  end

  def expect_to_be_on_case_created_page
    expect(page).to have_current_path(/\/cases\/([\d-]+)\/created/)
    expect(page).to have_selector("h1", text: "Case created")
    expect_no_error_messages
    expect(page).to have_text(/Case ID: ([\d-]+)/)
    expect(page).to have_text("#{product_details[:name]}, #{product_details[:type]} – #{hazard_type.downcase} hazard has now been assigned to you")
  end

  def expect_case_details_page_to_show_entered_information
    expect(page).to have_selector("h1", text: "Overview")

    expect(page).to have_text("#{product_details[:name]}, #{product_details[:type]} – #{hazard_type.downcase} hazard")
    expect(page).to have_text("Product reported because it is unsafe and non-compliant.")

    expect(page.find("dt", text: "Trading Standards reference")).to have_sibling("dd", text: reference_number)
    expect(page.find("dt", text: "Hazards")).to have_sibling("dd", text: hazard_type)
    expect(page.find("dt", text: "Hazards")).to have_sibling("dd", text: hazard_description)
    expect(page.find("dt", text: "Compliance")).to have_sibling("dd", text: non_compliance_details)
  end

  def expect_case_products_page_to_show(info:)
    expect(page).to have_selector("h1", text: "Products")

    expect(page).to have_selector("h2", text: info[:name])
    expect(page.find("dt", text: "Product name")).to have_sibling("dd", text: info[:name])
    expect(page.find("dt", text: "Barcode or serial number")).to have_sibling("dd", text: info[:barcode])
    expect(page.find("dt", text: "Product type")).to have_sibling("dd", text: info[:type])
    expect(page.find("dt", text: "Category")).to have_sibling("dd", text: info[:category])
    expect(page.find("dt", text: "Webpage")).to have_sibling("dd", text: info[:webpage])
    expect(page.find("dt", text: "Country of origin")).to have_sibling("dd", text: info[:country_of_origin])
    expect(page.find("dt", text: "Description")).to have_sibling("dd", text: info[:description])
  end

  def expect_case_businesses_page_to_show(label:, business:)
    expect(page).to have_selector("h1", text: "Businesses")

    expected_address = business.slice(:address_1, :address_2, :postcode, :country).values.join(", ")
    expected_contact = business.slice(:contact_name, :contact_job_title, :contact_phone, :contact_email).values.join(", ")

    section = page.find("h2", text: label).find("+dl")
    expect(section.find("dt", text: "Trading name")).to have_sibling("dd", text: business[:trading_name])
    expect(section.find("dt", text: "Registered or legal name")).to have_sibling("dd", text: business[:legal_name])
    expect(section.find("dt", text: "Company number")).to have_sibling("dd", text: business[:company_number])
    expect(section.find("dt", text: "Address")).to have_sibling("dd", text: expected_address)
    expect(section.find("dt", text: "Contact")).to have_sibling("dd", text: expected_contact)
  end

  def expect_case_attachments_page_to_show(file_description:)
    expect(page).to have_selector("h1", text: "Attachments")
    expect(page).to have_selector("h2", text: file_description)
  end

  def expect_case_activity_page_to_show_corrective_action(action)
    expect(page).to have_selector("h1", text: "Activity")
    item = page.find("h3", text: action[:summary]).find(:xpath, "..")
    expect(item).to have_text("Legislation: #{action[:legislation]}")
    expect(item).to have_text("Date came into effect: #{action[:date].strftime('%d/%m/%Y')}")
    expect(item).to have_text("Type of measure: #{CorrectiveAction.human_attribute_name("measure_type.#{action[:measure_type]}")}")
    expect(item).to have_text("Duration of action: #{CorrectiveAction.human_attribute_name("duration.#{action[:duration]}")}")
    expect(item).to have_text("Geographic scope: #{action[:geographic_scope]}")
    expect(item).to have_text("Attached: #{File.basename(action[:file])}")
    expect(item).to have_text(action[:details])
  end

  def expect_case_activity_page_to_show_risk_assessment(assessment)
    expect(page).to have_selector("h1", text: "Activity")
    item = page.find("h3", text: assessment[:title]).find(:xpath, "..")
    expect(item).to have_selector("p", text: assessment[:description])
  end

  def expect_case_activity_page_to_show_test_result(test)
    expect(page).to have_selector("h1", text: "Activity")
    item = page.find("h3", text: "#{test[:result]}ed test").find(:xpath, "..")
    expect(item).to have_text("Legislation: #{test[:legislation]}")
    expect(item).to have_text("Test date: #{test[:date].strftime('%d/%m/%Y')}")
    expect(item).to have_text(test[:details])
  end

  def fill_in_product_page(with:)
    select with[:category],          from: "Product category"
    select with[:country_of_origin], from: "Country of origin"
    fill_in "Product type",               with: with[:type]
    fill_in "Product name",               with: with[:name]
    fill_in "Barcode or serial number",   with: with[:barcode]
    fill_in "Webpage",                    with: with[:webpage]
    fill_in "Description of product",     with: with[:description]
    click_button "Continue"
  end

  def fill_in_why_reporting_page
    check "It’s unsafe (or suspected to be)"
    select hazard_type, from: "What is the primary hazard?"
    fill_in "Why is the product unsafe?", with: hazard_description
    check "It’s non-compliant (or suspected to be)"
    fill_in "Why is the product non-compliant?", with: non_compliance_details
    click_button "Continue"
  end

  def fill_in_supply_chain_page
    check "Retailer"
    check "Distributor"
    check "Other"
    fill_in "Other type", with: "advertiser"
    click_button "Continue"
  end

  def fill_in_business_details_page(with:)
    fill_in "Trading name",                  with: with[:trading_name]
    fill_in "Registered or legal name",      with: with[:legal_name]
    fill_in "Company number",                with: with[:company_number]
    fill_in "Address line one",              with: with[:address_1]
    fill_in "Address line two",              with: with[:address_2]
    fill_in "Town or city",                  with: with[:town]
    fill_in "County",                        with: with[:county]
    fill_in "Postcode",                      with: with[:postcode]
    fill_in "Name",                          with: with[:contact_name]
    fill_in "Email",                         with: with[:contact_email]
    fill_in "Phone number",                  with: with[:contact_phone]
    fill_in "Job title or role description", with: with[:contact_job_title]
    select with[:country], from: "Country"
    click_button "Continue"
  end

  def fill_in_corrective_action_taken_page
    choose "Yes"
    click_button "Continue"
  end

  def fill_in_record_corrective_action_page(with:)
    fill_in "Summary", with: with[:summary]
    fill_in "Day", with: with[:date].day
    fill_in "Month", with: with[:date].month
    fill_in "Year", with: with[:date].year
    select with[:legislation], from: "Under which legislation?"
    fill_in "Further details (optional)", with: with[:details]
    choose "corrective_action_related_file_yes"
    attach_file "corrective_action[file][file]", with[:file]
    fill_in "Attachment description", with: with[:file_description]
    choose "corrective_action_measure_type_#{with[:measure_type]}"
    choose "corrective_action_duration_#{with[:duration]}"
    select with[:geographic_scope], from: "What is the geographic scope of the action?"

    choose "corrective_action_further_corrective_action_yes"
    click_button "Continue"
  end

  def fill_in_other_information_page(test_results: true, risk_assessments: true)
    check "Test results" if test_results
    check "Risk assessments" if risk_assessments
    click_button "Continue"
  end

  def fill_in_test_results_page(with:)
    select with[:legislation], from: "Against which legislation?"
    fill_in "Day", with: with[:date].day
    fill_in "Month", with: with[:date].month
    fill_in "Year", with: with[:date].year
    choose with[:result]
    fill_in "Further details", with: with[:details]
    attach_file "test[file][file]", with[:file]
    choose "test_further_test_results_yes"
    click_button "Continue"
  end

  def fill_in_risk_assessment_details_page(with:)
    attach_file "file[file][file]", with[:file]
    fill_in "Title", with: with[:title]
    fill_in "Description", with: with[:description]
    choose "file_further_risk_assessments_yes"
    click_button "Continue"
  end

  def fill_in_reference_number_page(reference_number)
    choose "Yes"
    fill_in "Existing reference number", with: reference_number
    click_button "Create case"
  end

  def skip_page
    click_button "Skip this page"
  end
end
