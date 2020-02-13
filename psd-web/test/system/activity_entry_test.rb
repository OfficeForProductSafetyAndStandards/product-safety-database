require "application_system_test_case"

class ActivityEntryTest < ApplicationSystemTestCase
  setup do
    stub_antivirus_api
    stub_notify_mailer

    sign_in
    @investigation = load_case(:one)
    visit investigation_path(@investigation)
    click_on "Add activity"
  end

  test "Should go to an activity selection page" do
    assert_text "New activity"
  end

  test "Should require picking an activity type" do
    click_on "Continue"
    assert_text "Activity type must not be empty"
  end
end
