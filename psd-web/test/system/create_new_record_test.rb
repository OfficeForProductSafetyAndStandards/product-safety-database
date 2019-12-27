require "application_system_test_case"

class CreateNewRecordTest < ApplicationSystemTestCase
  setup do
    mock_out_keycloak_and_notify
    stub_antivirus_api
    visit new_investigation_path

    assert_css "h1", text: "Create new"
  end

  teardown do
    reset_keycloak_and_notify_mocks
  end

  test "can be reached via home page" do
    visit root_path
    click_on "Create new"

    assert_css "h1", text: "Create new"
  end

  test "should be prompted to select what to create" do
    assert_css "label", text: "Product safety allegation"
    assert_css "label", text: "Enquiry"

    assert_no_text "Please select an option before continuing"
  end

  test "should require an option to be selected" do
    click_on "Continue"

    assert_text "Please select an option before continuing"
  end

  test "should show the new allegation page when selecting allegation" do
    choose "type_allegation", visible: false
    click_on "Continue"

    assert_text "New allegation"
  end

  test "should show the new enquiry page when selecting enquiry" do
    choose "type_enquiry", visible: false
    click_on "Continue"

    assert_text "New enquiry"
  end
end
