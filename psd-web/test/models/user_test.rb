require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "display name includes user's organisation for non-org-member viewers" do
    assert_equal "Yann (Southampton Council)", users(:southampton).decorate.display_name(other_user: users(:opss))

    assert_equal "Slavosh (Office for Product Safety and Standards)", users(:opss).decorate.display_name(other_user: users(:southampton))
  end
end
