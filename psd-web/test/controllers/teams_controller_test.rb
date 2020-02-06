require "test_helper"

class TeamsControllerTest < ActionDispatch::IntegrationTest
  setup do
    stub_notify_mailer
    stub_user_management
    mock_keycloak_user_roles(%i[psd_user team_admin])
    sign_in users(:southampton)
    users(:southampton).teams << teams(:southampton)
    users(:southampton_bob).teams << teams(:southampton)
    User.current = users(:southampton)
  end

  teardown do
    restore_user_management
  end

  test "Team pages are visible to members" do
    get team_url(teams(:southampton))
    assert_response :success
  end

  test "Team pages are not visible to non-members" do
    assert_raises Pundit::NotAuthorizedError do
      get team_url(teams(:luton))
    end
  end

  test "Team invite pages are not visible to non-members" do
    assert_raises Pundit::NotAuthorizedError do
      get invite_to_team_url(teams(:luton))
    end
  end

  test "Team pages don’t include invite links for non-team-admins" do
    mock_keycloak_user_roles(%i[psd_user])
    get team_url(teams(:southampton))
    assert_not_includes(response.body, "Invite a team member")
  end

  test "Team invite pages are visible to users with team_admin role only" do
    mock_keycloak_user_roles(%i[psd_user])
    assert_raises Pundit::NotAuthorizedError do
      get invite_to_team_url(teams(:southampton))
    end
  end

  test "Inviting existing user from same org adds them to the team" do
    user_in_my_org_not_team = users(:southampton).organisation.users.find { |u| (u.teams & users(:southampton).teams).empty? }
    email_address = user_in_my_org_not_team.email

    assert_difference "teams(:southampton).users.count" => 1, "User.count" => 0 do
      put invite_to_team_url(teams(:southampton)), params: { new_user: { email_address: email_address } }
      assert_response :see_other
    end
  end

  test "Inviting existing user from same team returns error" do
    email_address = users(:southampton_bob).email
    assert_difference "teams(:southampton).users.count" => 0, "User.count" => 0 do
      put invite_to_team_url(teams(:southampton)), params: { new_user: { email_address: email_address } }
      assert_response :bad_request
    end
  end

  test "Inviting to team I'm not a member of is forbidden" do
    assert_raises Pundit::NotAuthorizedError do
      put invite_to_team_url(teams(:luton)), params: { new_user: { email_address: "email@address" } }
    end
  end

  test "Inviting existing user from different org doesn't add and shows error" do
    email_address = users(:luton).email
    assert_difference "teams(:southampton).users.count" => 0, "User.count" => 0 do
      put invite_to_team_url(teams(:southampton)), params: { new_user: { email_address: email_address } }
      assert_response :bad_request
    end
  end

  test "Inviting new user creates the account and adds them to the team" do
    kc = KeycloakClient.instance

    expect(kc).to receive(:send_required_actions_welcome_email)

    assert_difference "teams(:southampton).users.count" => 1, "User.all.size" => 1 do
      put invite_to_team_url(teams(:southampton)), params: { new_user: { email_address: "new_user@northamptonshire.gov.uk" } }
      assert_response :see_other
    end
  end

  test "Inviting user with email not on the whitelist returns an error" do
    allow(Rails.application.config).to receive(:email_whitelist_enabled).and_return(true)
    assert_difference "teams(:southampton).users.count" => 0, "User.count" => 0 do
      put invite_to_team_url(teams(:southampton)), params: { new_user: { email_address: "not_whitelisted@gmail.com" } }
      assert_response :bad_request
    end
  end

  test "Inviting user with email domain in whitelist is compared case-insensitively" do
    kc = KeycloakClient.instance

    expect(kc).to receive(:send_required_actions_welcome_email)

    assert_difference "teams(:southampton).users.count" => 1, "User.all.size" => 1 do
      put invite_to_team_url(teams(:southampton)), params: { new_user: { email_address: "new_user@NORTHAMPTONSHIRE.gov.uk" } }
      assert_response :see_other
    end
  end

  test "Resend invite when user is invited but not signed up" do
    email_address = "new_user@northamptonshire.gov.uk"
    put invite_to_team_url(teams(:southampton)), params: { new_user: { email_address: email_address } }
    put resend_invitation_team_path(email_address: email_address)
  end

  def stub_user_management
    allow(KeycloakClient.instance).to receive(:add_user_to_team)
    allow(KeycloakClient.instance).to receive(:create_user)
    allow(KeycloakClient.instance).to receive(:send_required_actions_welcome_email).and_return(true)
  end

  def restore_user_management
    allow(KeycloakClient.instance).to receive(:add_user_to_team).and_call_original
    allow(KeycloakClient.instance).to receive(:create_user).and_call_original
    allow(KeycloakClient.instance).to receive(:send_required_actions_welcome_email).and_call_original
  end

end
