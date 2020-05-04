require "test_helper"

class TeamsControllerTest < ActionDispatch::IntegrationTest
  setup do
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
end
