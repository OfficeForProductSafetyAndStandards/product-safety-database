require "application_system_test_case"

class HomepageTest < ApplicationSystemTestCase
  test "not signed in visits / stays on /" do
    visit "/"
    assert_text "if you think you should have access"
    refute_selector "a.psd-header__link", text: "BETA"
  end

  test "not signed in visits /cases gets redirected to /" do
    visit "/cases"
    assert_title "Sign in to Product safety database"
    refute_selector "a.psd-header__link", text: "BETA"
  end

  test "signed in visits / gets redirected to /cases" do
    mock_out_keycloak_and_notify
    sign_in_as(User.find_by(name: "Test User_one"))
    visit "/"
    assert_current_path "/cases"
    assert_selector "a.psd-header__link", text: "BETA"
    reset_keycloak_and_notify_mocks
  end

  test "signed in visits /cases stays on /cases" do
    mock_out_keycloak_and_notify
    sign_in_as(User.find_by(name: "Test User_one"))
    visit "/cases"
    assert_current_path "/cases"
    assert_selector "a.psd-header__link", text: "BETA"
    reset_keycloak_and_notify_mocks
  end
end
