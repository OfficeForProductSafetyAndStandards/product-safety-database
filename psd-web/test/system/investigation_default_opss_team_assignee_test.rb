require "application_system_test_case"

class InvestigationAssigneeTest < ApplicationSystemTestCase
  setup do
    stub_notify_mailer
    stub_antivirus_api
    @user = User.current = sign_in(users(:southampton), roles: %i[psd_user])
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

    assert_text "Assigned to #{teams(:opss_enforcement).name}"

    visit new_investigation_assign_path(load_case(:one))
    assert_text "Currently assigned to: Office for Product Safety and Standards"
    assert_text "You do not have permission to assign this allegation"
  end
end
