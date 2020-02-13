require "application_system_test_case"

class InvestigationHighlightTest < ApplicationSystemTestCase
  setup do
    Investigation.import refresh: :wait_for, force: true
    stub_notify_mailer
    stub_antivirus_api
    sign_in
    visit root_path
  end

  test "should display highlight title" do
    fill_in "q", with: "234", visible: false
    click_on "Search"
    assert_text "234"
    assert_text "Products, product code"
  end
end
