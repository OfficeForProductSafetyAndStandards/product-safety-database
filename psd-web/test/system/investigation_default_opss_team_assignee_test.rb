require "application_system_test_case"

class InvestigationAssigneeTest < ApplicationSystemTestCase
  setup do
    visit root_path
    sign_out
    stub_notify_mailer
    stub_antivirus_api
    @user = User.current = sign_in(users(:southampton))
    @user = @user.decorate
    @user.teams << teams(:southampton)
    @team = @user.teams.first
    visit new_investigation_assign_path(load_case(:one))
  end

  teardown { User.current = nil }

  test "non-OPSS assigns to OPSS, on re-assign sees the OPSS assign and no permission to reassign again" do
    assert_text @user.display_name
    choose "Other team", visible: false
    fill_autocomplete "investigation_select_other_team", with: "OPSS Enforcement"
    click_on "Continue"
    click_on "Confirm change"

    assert_text "Case owner #{teams(:opss_enforcement).name}"

    visit new_investigation_assign_path(load_case(:one))
    assert_text "Current case owner: Office for Product Safety and Standards"
    assert_text "You do not have permission to change the case owner"
  end
end
