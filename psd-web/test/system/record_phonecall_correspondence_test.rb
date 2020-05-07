require "application_system_test_case"
require_relative "../test_helpers/investigation_test_helper"

class RecordPhoneCallCorrespondenceTest < ApplicationSystemTestCase
  include InvestigationTestHelper

  setup do
    stub_notify_mailer
    stub_antivirus_api
    user = sign_in

    stub_antivirus_api
    @investigation = load_case(:one)
    @investigation.update!(source: UserSource.new(sourceable: user), owner: user)
    @correspondence = correspondences(:phone_call)
    visit new_investigation_phone_call_path(@investigation)
  end

  test "first step should be context" do
    assert_text("Who was the call with?")
  end

  test "first step validates date" do
    fill_in("correspondence_phone_call[correspondence_date][day]", with: "333")
    click_on "Continue"
    assert_text("Correspondence date must include a month and year")
  end

  test "second step should be content" do
    fill_in_context_form
    click_button "Continue"
    assert_text("Give an overview of the phone call")
  end

  test "attaches a transcript file" do
    fill_in_context_form
    click_button "Continue"
    attach_file("correspondence_phone_call[transcript][file]", file_fixture("testImage.png"))
    click_button "Continue"
    assert_text("testImage")
    click_button "Continue"

    assert_current_path(/cases\/\d+/)
    click_on "Activity"
    assert_text "Attached: testImage.png"
    assert_text "View attachment"
  end

  test "must have either transcript or summary and notes" do
    fill_in_context_form
    click_button "Continue"
    click_button "Continue"
    assert_text "Please provide either a transcript or complete the summary and notes fields"
  end

  test "third step should be confirmation" do
    fill_in_context_form
    click_button "Continue"
    fill_in_content_form
    click_button "Continue"
    assert_text "Confirm phone call details"
    assert_text "Attachments"
  end

  test "confirmation edit details should go to first page in flow" do
    fill_in_context_form
    click_button "Continue"
    fill_in_content_form
    click_button "Continue"
    click_on "Edit details"
    assert_text "Who was the call with?"
  end

  test "edit details should retain changed values" do
    fill_in_context_form
    click_button "Continue"
    fill_in_content_form
    click_button "Continue"
    click_on "Edit details"
    assert_equal(@correspondence.correspondent_name, find_field("correspondence_phone_call[correspondent_name]").value)
    assert_equal(@correspondence.phone_number, find_field("correspondence_phone_call[phone_number]").value)
  end

  test "confirmation continue should go to case page" do
    fill_in_context_form
    click_button "Continue"
    fill_in_content_form
    click_button "Continue"
    click_button "Continue"
    assert_current_path(/cases\/\d+/)
  end

  test "conceals information from other organisations on phonecalls with customer info" do
    fill_in_context_form
    choose :correspondence_phone_call_has_consumer_info_true, visible: false
    click_button "Continue"
    fill_in_content_form
    click_button "Continue"
    click_button "Continue"

    sign_out
    sign_in users(:southampton)
    visit investigation_path(@investigation)

    click_on "Activity"
    assert_equal("Phone call added", first("h3").text)
    assert_equal("RESTRICTED ACCESS", first(".hmcts-badge").text)
  end

  test "does not conceal consumer information from case owner" do
    fill_in_context_form
    choose :correspondence_phone_call_has_consumer_info_true, visible: false
    click_button "Continue"
    fill_in_content_form
    click_button "Continue"
    click_button "Continue"

    visit investigation_path(@investigation)

    click_on "Activity"
    assert_equal(@correspondence.overview, first("h3").text)
  end

  test "does not conceal consumer information from case owner's team" do
    fill_in_context_form
    choose :correspondence_phone_call_has_consumer_info_true, visible: false
    click_button "Continue"
    fill_in_content_form
    click_button "Continue"
    click_button "Continue"

    sign_out
    sign_in users(:opss_yann)
    visit investigation_path(@investigation)

    click_on "Activity"
    assert_equal(@correspondence.overview, first("h3").text)
  end

  test "does not conceal from other organisations information on phonecalls with customer info" do
    skip
    fill_in_context_form
    choose :correspondence_phone_call_has_consumer_info_true, visible: false
    click_button "Continue"
    fill_in_content_form
    click_button "Continue"
    click_button "Continue"

    sign_out
    sign_in users(:southampton)
    visit investigation_path(@investigation)

    click_on "Activity"
    assert_equal(@correspondence.overview, first("h3").text)
  end

  def fill_in_context_form
    fill_in "correspondence_phone_call[correspondent_name]", with: @correspondence.correspondent_name
    fill_in "correspondence_phone_call[phone_number]", with: @correspondence.phone_number
    fill_in "Day", with: @correspondence.correspondence_date.day
    fill_in "Month", with: @correspondence.correspondence_date.month
    fill_in "Year", with: @correspondence.correspondence_date.year
  end

  def fill_in_content_form
    fill_in "correspondence_phone_call[overview]", with: @correspondence.overview
    fill_in "correspondence_phone_call[details]", with: @correspondence.details
  end
end
