require "test_helper"

class TeamsControllerTest < ActionDispatch::IntegrationTest
  setup do
    stub_notify_mailer
    allow(Rails.application.config).to receive(:email_whitelist_enabled).and_return(true)
    mock_keycloak_user_roles([:psd_user, :team_admin])
    sign_in users(:southampton)
    users(:southampton).teams << teams(:southampton)
    @my_team = teams(:southampton)
    @another_team = Team.all.find { |t| !users(:southampton).teams.include?(t) }
  end

  teardown do
    reset_keycloak_and_notify_mocks
  end

  test "Team pages are visible to members" do
    get team_url(@my_team)
    assert_response :success
  end

  test "Team pages are not visible to non-members" do
    assert_raises Pundit::NotAuthorizedError do
      get team_url(@another_team)
    end

    assert_raises Pundit::NotAuthorizedError do
      get invite_to_team_url(@another_team)
    end
  end

  test "Team invite pages are visible to users with team_admin role only" do
    set_user_as_not_team_admin
    get team_url(@my_team)
    assert_not_includes(response.body, "Invite a team member")

    assert_raises Pundit::NotAuthorizedError do
      get invite_to_team_url(@my_team)
    end
  end

  test "Inviting existing user from same org adds them to the team" do
    user_in_my_org_not_team = users(:southampton).organisation.users.find { |u| (u.teams & users(:southampton).teams).empty? }
    email_address = user_in_my_org_not_team.email

    assert_difference "@my_team.users.count" => 1, "User.count" => 0 do
      put invite_to_team_url(@my_team), params: { new_user: { email_address: email_address } }
      assert_response :see_other
    end
    expect(NotifyMailer).to have_received(:user_added_to_team).with(email_address, any_args)
  end

  test "Inviting existing user from same team returns error" do
    email_address = @my_team.users.find { |u| u != users(:southampton) }.email
    assert_difference "@my_team.users.count" => 0, "User.count" => 0 do
      put invite_to_team_url(@my_team), params: { new_user: { email_address: email_address } }
      assert_response :bad_request
    end
    expect(NotifyMailer).not_to have_received(:user_added_to_team).with(email_address, any_args)
  end

  test "Inviting to team I'm not a member of is forbidden" do
    assert_raises Pundit::NotAuthorizedError do
      put invite_to_team_url(@another_team), params: { new_user: { email_address: "email@address" } }
    end
  end

  test "Inviting existing user from different org doesn't add and shows error" do
    email_address = users(:luton).email
    assert_difference "@my_team.users.count" => 0, "User.count" => 0 do
      put invite_to_team_url(@my_team), params: { new_user: { email_address: email_address } }
      assert_response :bad_request
    end
    expect(NotifyMailer).not_to have_received(:user_added_to_team).with(email_address, any_args)
  end

  test "Inviting new user creates the account and adds them to the team" do
    kc = KeycloakClient.instance

    expect(kc).to receive(:send_required_actions_welcome_email)

    assert_difference "@my_team.users.count" => 1, "User.all.size" => 1 do
      put invite_to_team_url(@my_team), params: { new_user: { email_address: "new_user@northamptonshire.gov.uk" } }
      assert_response :see_other
    end
  end

  test "Inviting user with email not on the whitelist returns an error" do
    assert_difference "@my_team.users.count" => 0, "User.count" => 0 do
      put invite_to_team_url(@my_team), params: { new_user: { email_address: "not_whitelisted@gmail.com" } }
      assert_response :bad_request
    end
  end

  test "Inviting user with email domain in whitelist is compared case-insensitively" do
    kc = KeycloakClient.instance

    expect(kc).to receive(:send_required_actions_welcome_email)

    assert_difference "@my_team.users.count" => 1, "User.all.size" => 1 do
      put invite_to_team_url(@my_team), params: { new_user: { email_address: "new_user@NORTHAMPTONSHIRE.gov.uk" } }
      assert_response :see_other
    end
  end

  test "Resend invite when user is invited but not signed up" do
    email_address = "new_user@northamptonshire.gov.uk"
    put invite_to_team_url(@my_team), params: { new_user: { email_address: email_address } }
    put resend_invitation_team_path(email_address: email_address)
    expect(NotifyMailer).not_to have_received(:user_added_to_team).with(email_address, any_args)
  end
end
