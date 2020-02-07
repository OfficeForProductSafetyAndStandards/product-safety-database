require "application_system_test_case"

class IntroductionTest < ApplicationSystemTestCase
  setup do
    stub_notify_mailer
    stub_antivirus_api

    visit "/"
  end

  test "shows steps in order then redirects to homepage" do
    sign_in(users(:southampton))
    mock_keycloak_user_roles([:psd_user])

    visit "/introduction/overview"
    assert_selector "h1", text: "Report, track and share product safety information"
    click_on "Continue"

    assert_current_path "/introduction/report_products"
    click_on "Continue"

    assert_current_path "/introduction/track_investigations"
    click_on "Continue"

    assert_current_path "/introduction/share_data"
    click_on "Get started"

    assert_text "Open a new case"
    assert_current_path "/"
  end

  test "clicking skip introduction skips introduction" do
    sign_in(users(:southampton))
    mock_keycloak_user_roles([:psd_user])

    visit "/introduction/overview"
    click_on "Skip introduction"

    assert_current_path "/"
  end

  test "users will not be shown the introduction twice" do
    sign_in(users(:southampton))
    mock_keycloak_user_roles([:psd_user])

    visit "/introduction/overview"
    click_on "Continue"
    click_on "Continue"
    click_on "Continue"
    click_on "Get started"
    visit "/"
    assert_current_path "/"
  end
end
