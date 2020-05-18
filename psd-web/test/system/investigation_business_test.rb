require "application_system_test_case"

class InvestigationBusinessTest < ApplicationSystemTestCase
  setup do
    stub_notify_mailer
    stub_antivirus_api
    sign_in users(:opss)
    @investigation = load_case(:one)
    @investigation.update!(owner: users(:opss).team)
    @business = businesses(:three)
    @business.source = sources(:business_three)
    @location = locations(:one)
    @contact = contacts(:one)
    visit new_investigation_business_path(@investigation)
  end

  test "should not create business if name is missing" do
    choose "business_type_importer", visible: false
    click_on "Continue"
    fill_in "business[legal_name]", with: @business.legal_name
    fill_in "business[trading_name]", with: ""
    fill_in "business[company_number]", with: @business.company_number
    click_on "Save business"
    assert_text "Trading name cannot be blank"
  end

  test "cannot allow business type to be empty" do
    click_on "Continue"
    assert_text "Please select a business type"
  end

  test "cannot allow business type other to be empty" do
    choose "business_type_other", visible: false
    click_on "Continue"
    assert_text 'Please enter a business type "Other"'
  end

  test "should unlink business" do
    visit remove_investigation_business_path(@investigation, @business)
    assert_text @business.trading_name
    click_on "Remove business"
    assert_no_text @business.trading_name
  end
end
