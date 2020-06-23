require "test_helper"

class InvestigationTest < ActiveSupport::TestCase
  include Pundit
  # Pundit requires this method to be able to call policies
  def pundit_user
    User.current
  end

  setup do
    user = users(:southampton)
    User.current = user
    allow_any_instance_of(NotifyMailer).to receive(:mail) { true }

    @investigation = load_case(:one)
    user.own!(@investigation)
    @business = businesses(:biscuit_base)
  end

  test "should create an activity when business is added to investigation" do
    @investigation = create_new_case
    assert_difference "Activity.count" do
      @business = businesses :new_business
      @investigation.add_business @business, "manufacturer"
    end
  end

  test "should create an activity when business is removed from investigation" do
    @investigation = create_new_case
    @business = businesses :new_business
    @investigation.add_business @business, "retailer"
    assert_difference "Activity.count" do
      @investigation.businesses.delete(@business)
    end
  end

  test "should create an activity when status is updated on investigation" do
    @investigation = create_new_case
    assert_difference "Activity.count" do
      @investigation.is_closed = !@investigation.is_closed
      @investigation.save
    end
  end

  test "visible to creator organisation" do
    create_new_private_case(users(:southampton))
    user = users(:southampton_steve)
    assert_equal(policy(@new_investigation).view_non_protected_details?(user: user), true)
  end

  test "visible to owner organisation" do
    create_new_private_case(users(:southampton))
    owner = users(:southampton_steve)
    owner.own!(@new_investigation)

    assert(policy(@new_investigation).view_non_protected_details?(user: owner))
  end

  test "past owners should be computed" do
    user = users(:southampton_bob)
    ChangeCaseOwner.call!(investigation: @investigation, owner: user, user: user)
    assert_includes @investigation.past_owners, user
  end

  test "people out of current owner's team should not be able to change the case owner" do
    investigation = create_new_case(users(:southampton))
    assert_not policy(investigation).change_owner_or_status?(user: users(:luton))
  end

  test "people not in the team that is the case owner should not be able to change the case owner" do
    investigation = create_new_case
    User.current.team.own!(investigation)
    assert_not policy(investigation).change_owner_or_status?(user: users(:luton))
  end

  def create_new_private_case(user)
    description = "new_investigation_description"
    @new_investigation = Investigation::Allegation.new(description: description, is_private: true)

    CreateCase.call(investigation: @new_investigation, user: user)
  end
end
