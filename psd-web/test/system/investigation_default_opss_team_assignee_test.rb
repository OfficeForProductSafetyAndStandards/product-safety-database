require "application_system_test_case"

class InvestigationAssigneeTest < ApplicationSystemTestCase
  setup do
    mock_out_keycloak_and_notify(name: "Ts_user") # non-OPSS
    @user = User.current
    @team = @user.teams.first
    Rails.application.config.team_names = {
      "organisations" => {
        "opss" => [
          "Team 4", # This should be the default
          "OPSS Processing",
          "OPSS Trading Standards Co-ordination"
        ]
      }
    }
    visit new_investigation_assign_path(load_case(:one))
  end

  teardown do
    reset_keycloak_and_notify_mocks
  end

  test "non-OPSS assigns to OPSS, on re-assign sees the OPSS assign and no permission to reassign again" do
    assert_text "Office of Product Safety and Standards"
    choose "Office of Product Safety and Standards", visible: false
    click_on "Continue"
    click_on "Confirm change"
    assert_text "Assigned to Team 4"
    visit new_investigation_assign_path(load_case(:one))
    assert_text "Currently assigned to: Office of Product Safety and Standards"
    assert_text "You do not have permission to assign this allegation"
  end
end
