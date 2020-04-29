require "test_helper"

class TeamsControllerTest < ActionDispatch::IntegrationTest
  setup do
    stub_notify_mailer
    sign_in users(:southampton)
    users(:southampton).teams << teams(:southampton)
    users(:southampton_bob).teams << teams(:southampton)
    User.current = users(:southampton)
  end

  teardown do
    User.current = nil
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

  test "Team invite pages are visible to users with team_admin role only" do
    sign_out(:user)
    sign_in(users(:southampton_bob))

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

  test "Inviting user with email not on the whitelist returns an error" do
    allow(Rails.application.config).to receive(:email_whitelist_enabled).and_return(true)
    not_whitelisted_address = "not_whitelisted@gmail.com"
    assert_difference "teams(:southampton).users.count" => 0, "User.count" => 0 do
      put invite_to_team_path(teams(:southampton)), params: { new_user: { email_address: not_whitelisted_address } }
      assert_response :bad_request
    end
  end
end
