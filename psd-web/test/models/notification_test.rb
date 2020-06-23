require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  setup do
    stub_notify_mailer
    @user = users(:southampton)

    @investigation = Investigation::Allegation.new(description: "new investigation for notification test")
    CreateCase.call(investigation: @investigation, user: @user)

    User.current = @user
  end

  teardown do
    allow(NotifyMailer).to receive(:investigation_updated).and_call_original
    allow(NotifyMailer).to receive(:investigation_created).and_call_original
    User.current = nil
  end

  test "should notify current owner when the owner is a person and there is any change" do
    users(:southampton_steve).own!(@investigation)
    @investigation.reload
    mock_investigation_updated(who_will_be_notified: [users(:southampton_steve).email])
    make_generic_change
    assert_equal @number_of_notifications, 1
  end

  test "should not notify current owner when the owner makes the change" do
    teams(:southampton_team).own!(@investigation)
    mock_investigation_updated(who_will_be_notified: [])
    make_generic_change
    assert_equal @number_of_notifications, 0
  end

  test "should not notify anyone when the owner is a team and there is any change done by team users" do
    teams(:southampton_team).own!(@investigation)
    mock_investigation_updated(who_will_be_notified: [])
    make_generic_change
    assert_equal @number_of_notifications, 0
  end

  test "should notify all team members when the owner is a team and there is any change done by outsiders" do
    opss_enforcement = teams(:opss_enforcement)
    opss_enforcement.own!(@investigation)
    mock_investigation_updated(who_will_be_notified: [users(:southampton_bob).email])
    make_generic_change
    assert_equal @number_of_notifications, 0
  end

  test "should notify creator and owner when case is closed or reopened by someone else" do
    @investigation.update!(creator_user: users(:southampton))
    users(:southampton).own!(@investigation)
    mock_investigation_updated(who_will_be_notified: [users(:southampton), users(:southampton_bob)].map(&:email))
    @investigation.update(is_closed: !@investigation.is_closed)
    assert_equal 0, @number_of_notifications
    @investigation.update(is_closed: !@investigation.is_closed)
    assert_equal 0, @number_of_notifications
  end

  test "should not notify creator when case is closed or reopened by the creator" do
    @investigation.update!(creator_user: users(:southampton))
    users(:southampton_bob).own!(@investigation)
    @investigation.reload
    mock_investigation_updated(who_will_be_notified: [users(:southampton_bob).email])
    @investigation.update(is_closed: !@investigation.is_closed)
    assert_equal 1, @number_of_notifications
    @investigation.update(is_closed: !@investigation.is_closed)
    assert_equal 2, @number_of_notifications
  end

  test "notifies current user when investigation created" do
    mock_investigation_created(who_will_be_notified: [users(:southampton)])
    @investigation_two = investigations :two
    new_investigation = Investigation::Allegation.new(@investigation_two.attributes.merge(id: 123))
    CreateCase.call(investigation: new_investigation, user: @user)
    assert_equal @number_of_notifications, 1
  end

  test "Team is notified correctly" do
    team_with_email = teams(:luton_team)
    team_with_email.own!(@investigation)
    @investigation.reload
    mock_investigation_updated(who_will_be_notified: [team_with_email.team_recipient_email])
    make_generic_change
    assert_equal @number_of_notifications, 1
  end

  def mock_investigation_updated(who_will_be_notified: [])
    notify_mailer_return_value = ""
    @number_of_notifications = 0
    allow(notify_mailer_return_value).to receive(:deliver_later)
    allow(NotifyMailer).to receive(:investigation_updated) do |_id, _user_name, email, _text|
      @number_of_notifications += 1
      assert_includes who_will_be_notified, email
      notify_mailer_return_value
    end
  end

  def mock_investigation_created(who_will_be_notified: [])
    notify_mailer_return_value = ""
    @number_of_notifications = 0
    allow(notify_mailer_return_value).to receive(:deliver_later)
    allow(NotifyMailer).to receive(:investigation_created) do |_id, user_name, _user_email, _investigation_title, _investigation_type|
      @number_of_notifications += 1
      assert_includes who_will_be_notified.map(&:name), user_name
      notify_mailer_return_value
    end
  end

  def make_generic_change
    # Should not be changing the owner, since it's a special case
    @investigation.add_business(Business.create(trading_name: "Test Company"), "Test relationship")
  end
end
