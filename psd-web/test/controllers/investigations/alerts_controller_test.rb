require "test_helper"

class Investigations::AlertsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:southampton)
    mock_keycloak_user_roles([:psd_user])
    @investigation = load_case(:private)
    @investigation.source = sources(:investigation_private)
  end

  test "prevents creation of alert on private investigation" do
    assert_raise(Pundit::NotAuthorizedError)  { get investigation_alert_url(@investigation, id: "compose") }
  end
end
