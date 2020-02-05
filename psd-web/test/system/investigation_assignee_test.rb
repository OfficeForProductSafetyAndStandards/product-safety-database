require "application_system_test_case"

class InvestigationAssigneeTest < ApplicationSystemTestCase
  setup do
    stub_notify_mailer
    stub_antivirus_api

    @user = sign_in
    @team = @user.teams.first
    visit new_investigation_assign_path(load_case(:one))
  end

  test "should show current user as a radio, and to assign user to case" do
    assert_text @user.display_name
    choose @user.display_name, visible: false
    click_on "Continue"
    click_on "Confirm change"
    assert_text "Assigned to #{@user.name}\n#{@user.organisation.name}"
    click_on "Activity"
    assert_text "Assigned to #{@user.display_name}"
  end

  test "should show current users team as a radio, and to assign team to case" do
    assert_text @team.name
    choose @team.name, visible: false
    click_on "Continue"
    click_on "Confirm change"
    assert_text "Assigned to #{@team.name}"
    click_on "Activity"
    assert_text "Assigned to #{@team.name}"
  end

  test "should add comment to assignment activity" do
    assert_text @team.name
    choose @team.name, visible: false
    click_on "Continue"
    fill_in "Message to new assignee (optional)", with: "Test assignment comment"
    click_on "Confirm change"
    assert_text "Assigned to #{@team.name}"
    click_on "Activity"
    assert_text "Assigned to #{@team.name}"
    assert_text "Test assignment comment"
  end
end
