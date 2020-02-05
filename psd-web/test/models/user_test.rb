require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    mock_out_keycloak_and_notify
    @user = User.find_by(name: "Test User_one")
    @user_four = User.find_by(name: "Test User_four")

    mock_user_as_non_opss(@user)
    mock_user_as_opss(@user_four)
  end

  test "display name includes user's organisation for non-org-member viewers" do
    sign_in_as @user_four
    assert_equal "Test User_one (Organisation 1)", @user.display_name

    sign_in_as @user
    assert_equal "Test User_four (Office of Product Safety and Standards)", @user_four.display_name
  end
end
