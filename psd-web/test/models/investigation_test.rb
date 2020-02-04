require "test_helper"

class InvestigationTest < ActiveSupport::TestCase
  include Pundit
  # Pundit requires this method to be able to call policies
  def pundit_user
    User.current
  end

  setup do
    mock_keycloak_user_roles([:psd_user])
    user = users(:southampton)
    User.current = user
    allow_any_instance_of(NotifyMailer).to receive(:mail) { true }

    @investigation = load_case(:one)
    @business = businesses(:biscuit_base)
  end

  test "should create activity when investigation is created" do
    assert_difference "Activity.count" do
      @investigation = create_new_case
    end
  end

  test "should create an activity when business is added to investigation" do
    @investigation = create_new_case
    assert_difference"Activity.count" do
      @business = businesses :new_business
      @investigation.add_business @business, "manufacturer"
    end
  end

  test "should create an activity when business is removed from investigation" do
    @investigation = create_new_case
    @business = businesses :new_business
    @investigation.add_business @business, "retailer"
    assert_difference"Activity.count" do
      @investigation.businesses.delete(@business)
    end
  end

  test "should create an activity when product is added to investigation" do
    @investigation = create_new_case
    assert_difference"Activity.count" do
      @product = Product.new(name: "Test Product", product_type: "test product type", category: "test product category")
      @investigation.products << @product
    end
  end

  test "should create an activity when product is removed from investigation" do
    @investigation = create_new_case
    @product = Product.new(name: "Test Product", product_type: "test product type", category: "test product category")
    @investigation.products << @product
    assert_difference"Activity.count" do
      @investigation.products.delete(@product)
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
    create_new_private_case
    creator = User.find_by(name: "Test User_one")
    mock_user_as_non_opss(creator)
    user = User.find_by(name: "Test User_two")
    mock_user_as_non_opss(user)
    assert_equal(policy(@new_investigation).show?(user: user), true)
  end

  test "visible to assignee organisation" do
    create_new_private_case
    assignee = User.find_by(name: "Test User_two")

    mock_user_as_opss(assignee)

    expect(KeycloakClient.instance).
      to receive(:get_user_roles).with(assigne.id).and_return(%i[psd_user opss_user])

    user = User.find_by(name: "Test User_three")
    mock_user_as_opss(user)
    @new_investigation.assignee = assignee
    assert(policy(@new_investigation).show?(user: user))
  end

  test "not visible to no-source, no-assignee organisation" do
    user = users(:luton)
    create_new_private_case
    assert_not(policy(@new_investigation).show?(user: user))
  end

  test "past assignees should be computed" do
    user = users(:southampton)
    @investigation.update(assignee: user)
    assert_includes @investigation.past_assignees, user
  end

  test "past assignee teams should be computed" do
    team = Team.first
    @investigation.update(assignee: team)
    assert_includes @investigation.past_teams, team
  end

  test "people out of current assignee's team should not be able to re-assign case" do
    investigation = create_new_case
    investigation.assignee = User.find_by(name: "Test User_one")
    assert_not policy(investigation).assign?(user: User.find_by(name: "Test User_three"))
  end

  test "people in current assignee's team should be able to re-assign case" do
    investigation = create_new_case
    investigation.assignee = User.find_by(name: "Test User_one")
    assert policy(investigation).assign?(user: User.find_by(name: "Test User_two"))
  end

  test "people out of currently assigned team should not be able to re-assign case" do
    investigation = create_new_case
    investigation.assignee = Team.find_by(name: "Team 1")
    assert_not policy(investigation).assign?(user: User.find_by(name: "Test User_three"))
  end

  test "people in currently assigned team should be able to re-assign case" do
    investigation = create_new_case
    investigation.assignee = Team.find_by(name: "Team 1")
    assert policy(investigation).assign?(user: User.find_by(name: "Test User_four"))
  end

  test "pretty_id should contain YYMM" do
    investigation = create_new_case
    assert_includes investigation.pretty_id, Time.zone.now.strftime("%y").to_s
    assert_includes investigation.pretty_id, Time.zone.now.strftime("%m").to_s
  end

  test "pretty_id should be unique" do
    10.times do
      create_new_case
    end
    investigation = create_new_case
    assert_equal Investigation.where(pretty_id: investigation.pretty_id).count, 1
  end

  test "assigns to current user by default" do
    investigation = create_new_case
    assert_equal User.current, investigation.assignee
  end

  def create_new_private_case
    description = "new_investigation_description"
    @new_investigation = Investigation::Allegation.create(description: description, is_private: true)
  end
end
