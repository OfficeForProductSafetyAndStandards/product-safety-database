require "rails_helper"

RSpec.feature "Reporting a product", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:reference_number) { Faker::Number.number(digits: 10) }
  let(:hazard_type) { Rails.application.config.hazard_constants["hazard_type"].sample }
  let(:hazard_description) { Faker::Lorem.paragraph }
  let(:non_compliance_details) { Faker::Lorem.paragraph }

  let(:business_details) do
    business = lambda {
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

  let(:corrective_actions) do
    action = lambda {
      {
        action: "other",
        other_action: Faker::Lorem.sentence,
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
  end

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

  let(:risk_assessments) do
    assessment = lambda {
      {
        file: Rails.root + "test/fixtures/files/new_risk_assessment.txt",
        title: Faker::Lorem.sentence,
        description: Faker::Lorem.paragraph,
        risk_level: RiskAssessment.risk_levels.values.sample.titleize,
        business_type: business_details.keys.sample
      }
    }

    [
      assessment.call,
      assessment.call
    ]
  end

  context "when signed in as a non-OPSS user" do
    let(:user) { create(:user, :activated, :viewed_introduction, :psd_user).decorate }

    before { sign_in user }

    context "with full details" do
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
      let(:coronavirus) { false }

      scenario "not coronavirus-related" do
        visit new_ts_investigation_path

        expect_to_be_on_coronavirus_page("/ts_investigation/coronavirus")
        fill_in_coronavirus_page(coronavirus)

        expect_to_be_on_what_product_are_you_reporting_page
        fill_in_product_page(with: product_details)

        expect_to_be_on_why_reporting_page
        fill_in_why_reporting_page(
          reporting_reasons: ["It’s unsafe (or suspected to be)", "It’s non-compliant (or suspected to be)"],
          hazard_type: hazard_type,
          hazard_description: hazard_description,
          non_compliance_details: non_compliance_details
        )

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

        corrective_actions.each do |corrective_action_attributes|
          fill_in_record_corrective_action_page(with: corrective_action_attributes)
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

        # trigger validation to verify state in session is cleaned up correctly
        click_on "Continue"

        risk_assessments.each do |assessment|
          fill_in_risk_assessment_details_page(with: assessment)
          expect_to_be_on_risk_assessment_details_page
        end

        skip_page

        expect_to_be_on_reference_number_page
        fill_in_reference_number_page(reference_number)

        expect_to_be_on_case_created_page
        expect(page).to have_text("You are now the case owner for #{product_details[:name]}, #{product_details[:type]} – #{hazard_type.downcase}")

        click_link "View case"

        expect_to_be_on_case_page
        expect_case_details_page_to_show_entered_information
        expect_product_reported_unsafe_and_non_compliant

        expect(page.find("dt.govuk-summary-list__key", text: "Coronavirus related")).to have_sibling("dd.govuk-summary-list__value", text: "Not a coronavirus related case")

        click_link "Products (1)"

        expect_to_be_on_case_products_page
        expect_case_products_page_to_show(info: product_details)

        click_link "Businesses (2)"

        expect_case_businesses_page_to_show(label: "Retailer", business: business_details[:retailer])
        expect_case_businesses_page_to_show(label: "Advertiser", business: business_details[:advertiser])

        click_link "Supporting information (5)"

        risk_assessments.each do |assessment|
          expect_case_supporting_information_page_to_show(assessment)
        end

        click_link "Activity"

        expect_to_be_on_case_activity_page
        expect_case_activity_page_to_show_allegation_logged
        expect_case_activity_page_to_show_product_added
        corrective_actions.each { |action| expect_case_activity_page_to_show_corrective_action(action) }
        test_results.each { |test| expect_case_activity_page_to_show_test_result(test) }
        risk_assessments.each { |assessment| expect_case_activity_page_to_show_risk_assessment(assessment) }
      end
    end

    context "with minimum details" do
      let(:product_details) do
        {
          name: Faker::Lorem.sentence,
          category: Rails.application.config.product_constants["product_category"].sample,
          type: Faker::Appliance.equipment,
        }
      end

      let(:coronavirus) { true }

      scenario "coronavirus-related, with input errors" do
        visit new_ts_investigation_path

        expect_to_be_on_coronavirus_page("/ts_investigation/coronavirus")

        # Do not select an option
        click_button "Continue"

        expect_to_be_on_coronavirus_page("/ts_investigation/coronavirus")
        expect(page).to have_error_summary "Select whether or not the case is related to the coronavirus outbreak"

        fill_in_coronavirus_page(coronavirus)

        expect_to_be_on_what_product_are_you_reporting_page
        click_button "Continue"

        expect_to_be_on_what_product_are_you_reporting_page
        expect(page).to have_error_summary "Name cannot be blank", "Product type cannot be blank", "Category cannot be blank"

        fill_in_product_page(with: product_details)

        expect_to_be_on_why_reporting_page
        click_button "Continue"

        expect_to_be_on_why_reporting_page
        expect(page).to have_error_summary "Choose at least one option"

        check "It’s non-compliant (or suspected to be)"

        click_button "Continue"

        expect_to_be_on_why_reporting_page
        expect(page).to have_error_summary "Non compliant reason cannot be blank"

        fill_in "Why is the product non-compliant?", with: non_compliance_details
        click_button "Continue"

        expect_to_be_on_supply_chain_page
        click_button "Continue"

        expect_to_be_on_supply_chain_page
        expect(page).to have_error_summary "Indicate which if any business is known"

        check "None of the above"
        click_button "Continue"

        expect_to_be_on_corrective_action_taken_page
        click_button "Continue"

        expect_to_be_on_corrective_action_taken_page
        expect(page).to have_error_summary "Select whether or not you have corrective action to record"

        choose "No"
        click_button "Continue"

        expect_to_be_on_other_information_page
        click_button "Continue"

        expect_to_be_on_reference_number_page
        click_button "Create case"

        expect_to_be_on_reference_number_page
        expect(page).to have_error_summary "Choose whether you want to add your own reference number"

        choose "No"
        click_button "Create case"

        expect_to_be_on_case_created_page
        expect(page).to have_text("You are now the case owner for #{product_details[:name]}, #{product_details[:type]}")

        click_link "View case"

        expect_to_be_on_case_page
        expect(page).to have_text("#{product_details[:name]}, #{product_details[:type]}")
        expect(page).to have_text("Product reported because it is non-compliant.")
        expect(page.find("dt", text: "Coronavirus related")).to have_sibling("dd", text: "Coronavirus related case")

        click_link "Products (1)"

        expect_to_be_on_case_products_page
        expect_case_products_page_to_show(info: product_details)

        click_link "Activity"

        expect_to_be_on_case_activity_page
        expect_case_activity_page_to_show_allegation_logged
        expect_case_activity_page_to_show_product_added
      end
    end
  end

  def expect_case_details_page_to_show_entered_information
    expect(page).to have_text("#{product_details[:name]}, #{product_details[:type]} – #{hazard_type.downcase} hazard")
    expect(page).to have_text("Product reported because it is unsafe and non-compliant.")

    expect(page.find("dt", text: "Trading Standards reference")).to have_sibling("dd", text: reference_number)
    expect(page.find("dt", text: "Hazards")).to have_sibling("dd", text: hazard_type)
    expect(page.find("dt", text: "Hazards")).to have_sibling("dd", text: hazard_description)
    expect(page.find("dt", text: "Compliance")).to have_sibling("dd", text: non_compliance_details)
    expect(page.find("dt", text: "Coronavirus related")).to have_sibling("dd", text: "Not a coronavirus related case")
  end

  def expect_case_products_page_to_show(info:)
    expect(page).to have_selector("h2", text: info[:name])
    expect(page.find("dt", text: "Product name")).to have_sibling("dd", text: info[:name])
    expect(page.find("dt", text: "Barcode or serial number")).to have_sibling("dd", text: info[:barcode]) if info[:barcode]
    expect(page.find("dt", text: "Product type")).to have_sibling("dd", text: info[:type])
    expect(page.find("dt", text: "Category")).to have_sibling("dd", text: info[:category])
    expect(page.find("dt", text: "Webpage")).to have_sibling("dd", text: info[:webpage]) if info[:webpage]
    expect(page.find("dt", text: "Country of origin")).to have_sibling("dd", text: info[:country_of_origin]) if info[:country_of_origin]
    expect(page.find("dt", text: "Description")).to have_sibling("dd", text: info[:description]) if info[:description]
  end

  def expect_case_businesses_page_to_show(label:, business:)
    expect(page).to have_selector("h1", text: "Businesses")

    expected_address = business.slice(:address_1, :address_2, :town, :postcode, :country).values.join(", ")
    expected_contact = business.slice(:contact_name, :contact_job_title, :contact_phone, :contact_email).values.join(", ")

    section = page.find("h2", text: label).find("+dl")
    expect(section.find("dt", text: "Trading name")).to have_sibling("dd", text: business[:trading_name])
    expect(section.find("dt", text: "Registered or legal name")).to have_sibling("dd", text: business[:legal_name])
    expect(section.find("dt", text: "Company number")).to have_sibling("dd", text: business[:company_number])
    expect(section.find("dt", text: "Address")).to have_sibling("dd", text: expected_address)
    expect(section.find("dt", text: "Contact")).to have_sibling("dd", text: expected_contact)
  end

  def expect_case_supporting_information_page_to_show(assessment_attributes)
    expect(page).to have_css("h1", text: "Supporting information")

    if assessment_attributes[:risk_level] != "Other"
      expect(page).to have_link("#{assessment_attributes[:risk_level]} risk: #{product_details[:name]}")
    else
      expect(page).to have_link("#{assessment_attributes[:custom_risk_level]}: #{product_details[:name]}")
    end
  end

  def expect_case_activity_page_to_show_allegation_logged
    item = page.find("h3", text: "Allegation logged: #{product_details[:name]}, #{product_details[:type]}").find(:xpath, "..")
    expect(item).to have_text("Case owner: #{user.name}")
    expect(item).to have_text("Case is related to the coronavirus outbreak") if coronavirus
  end

  def expect_case_activity_page_to_show_product_added
    item = page.find("p", text: "Product added").find(:xpath, "..")
    expect(item).to have_text(product_details[:name])
    expect(item).to have_text("Product added by #{user.name}")
    expect(item).to have_link("View product details")
  end

  def expect_case_activity_page_to_show_corrective_action(action)
    item = page.find("h3", text: action[:other_action]).find(:xpath, "..")
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
    if assessment[:risk_level] != "Other"
      expect(page).to have_css(".govuk-body", text: /Risk level: #{assessment[:risk_level]} risk/)
    else
      expect(page).to have_css(".govuk-body", text: /Risk level: #{Regexp.escape(assessment[:custom_risk_level])}/)
    end
  end

  def expect_case_activity_page_to_show_test_result(test)
    expect(page).to have_selector("h1", text: "Activity")
    item = page.find("h3", text: "#{test[:result]}ed test").find(:xpath, "..")
    expect(item).to have_text("Legislation: #{test[:legislation]}")
    expect(item).to have_text("Test date: #{test[:date].strftime('%d/%m/%Y')}")
    expect(item).to have_text(test[:details])
  end

  def fill_in_coronavirus_page(answer)
    within_fieldset("Is this case related to the coronavirus outbreak?") do
      choose answer ? "Yes, it is (or could be)" : "No, this is business as usual"
    end

    click_button "Continue"
  end

  def fill_in_product_page(with:)
    select with[:category],          from: "Product category"
    select with[:country_of_origin], from: "Country of origin" if with[:country_of_origin]
    fill_in "Product type",               with: with[:type]
    fill_in "Product name",               with: with[:name]
    fill_in "Barcode or serial number",   with: with[:barcode] if with[:barcode]
    fill_in "Webpage",                    with: with[:webpage] if with[:webpage]
    fill_in "Description of product",     with: with[:description] if with[:description]
    click_button "Continue"
  end

  def fill_in_why_reporting_page(reporting_reasons:, hazard_type: nil, hazard_description: nil, non_compliance_details: nil)
    reporting_reasons.each do |reporting_reason|
      check reporting_reason
    end

    if reporting_reasons.include?("It’s unsafe (or suspected to be)")
      select hazard_type, from: "What is the primary hazard?"
      fill_in "Why is the product unsafe?", with: hazard_description
    end

    if reporting_reasons.include?("It’s non-compliant (or suspected to be)")
      fill_in "Why is the product non-compliant?", with: non_compliance_details
    end

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
    fill_in "Trading name",                    with: with[:trading_name]
    fill_in "Registered or legal name",        with: with[:legal_name]
    fill_in "Company number",                  with: with[:company_number]
    fill_in "Building and street line 1 of 2", with: with[:address_1]
    fill_in "Building and street line 2 of 2", with: with[:address_2]
    fill_in "Town or city",                    with: with[:town]
    fill_in "County",                          with: with[:county]
    fill_in "Postcode",                        with: with[:postcode]
    fill_in "Name",                            with: with[:contact_name]
    fill_in "Email",                           with: with[:contact_email]
    fill_in "Phone number",                    with: with[:contact_phone]
    fill_in "Job title or role description",   with: with[:contact_job_title]
    select with[:country], from: "Country"
    click_button "Continue"
  end

  def fill_in_corrective_action_taken_page
    choose "Yes"
    click_button "Continue"
  end

  def fill_in_record_corrective_action_page(with:)
    within_fieldset("What action is being taken?") do
      choose "Other"
      fill_in "Other action", with: with[:other_action]
    end
    fill_in "Day", with: with[:date].day
    fill_in "Month", with: with[:date].month
    fill_in "Year", with: with[:date].year
    select with[:legislation], from: "Under which legislation?"
    fill_in "Further details (optional)", with: with[:details]

    within_fieldset "Are there any files related to the action?" do
      choose "Yes"
    end

    attach_file "Upload a file", with[:file], visible: false
    fill_in "Attachment description", with: with[:file_description]

    within_fieldset "Is the corrective action mandatory?" do
      choose with[:measure_type] == "mandatory" ? "Yes" : "No, it’s voluntary"
    end

    within_fieldset "How long will the corrective action be in place?" do
      choose with[:duration].titleize
    end

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
    attach_file "Upload a file", with[:file]
    choose "test_further_test_results_yes"
    click_button "Continue"
  end

  def fill_in_risk_assessment_details_page(with:)
    within_fieldset("Date of assessment") do
      fill_in("Day", with: "3")
      fill_in("Month", with: "4")
      fill_in("Year", with: "2020")
    end

    within_fieldset("What was the risk level?") do
      choose with[:risk_level]
      if with[:risk_level] == "Other"
        with[:custom_risk_level] = Faker::Hipster.sentence
        fill_in "Other risk level", with: with[:custom_risk_level]
      end
    end

    within_fieldset("Who completed the assessment?") do
      choose "A business related to the case"
      select business_details[with[:business_type]][:trading_name]
    end

    expect(page.find(".govuk-heading-m")).to have_sibling("p.govuk-body", text: product_details[:name])

    attach_file "trading_standards_risk_assessment_form[risk_assessment_file]", with[:file]

    within_fieldset("Are there other risk assessments to report?") do
      choose "Yes"
    end

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

  def expect_product_reported_unsafe_and_non_compliant
    expect(page.find("h2", text: "Summary")).to have_sibling("p", text: "Product reported because it is unsafe and non-compliant.")
  end
end
