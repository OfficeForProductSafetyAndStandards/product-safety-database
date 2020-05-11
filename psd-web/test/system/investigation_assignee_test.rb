require "application_system_test_case"

class InvestigationAssigneeTest < ApplicationSystemTestCase
  setup do
    stub_notify_mailer
    stub_antivirus_api

    @user = users(:opss).decorate
    User.current = @user
    sign_in @user
    @user.teams << teams(:opss_enforcement)
    @team = @user.teams.first
    visit new_investigation_ownership_path(load_case(:one))
  end

  teardown { User.current = nil }

  test "should show current user as a radio, and to make the user as the case owner" do
    assert_text @user.display_name
    choose @user.display_name, visible: false
    click_on "Continue"
    click_on "Confirm change"
    assert_text "Case owner #{@user.name}\n#{@user.organisation.name}"
    click_on "Activity"
    assert_text "Case owner changed to #{@user.display_name}"
  end

  test "should show current users team as a radio, and to make team as the case owner" do
    assert_text @team.name
    choose @team.name, visible: false
    click_on "Continue"
    click_on "Confirm change"
    assert_text "Case owner #{@team.name}"
    click_on "Activity"
    assert_text "Case owner changed to #{@team.name}"
  end

  test "should add comment to ownership change activity" do
    assert_text @team.name
    choose @team.name, visible: false
    click_on "Continue"
    fill_in "Message to new case owner (optional)", with: "Test comment"
    click_on "Confirm change"
    assert_text "Case owner #{@team.name}"
    click_on "Activity"
    assert_text "Case owner changed to #{@team.name}"
    assert_text "Test comment"
  end
end
