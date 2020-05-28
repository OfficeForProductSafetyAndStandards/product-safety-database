require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  setup do
    stub_notify_mailer
    @investigation = Investigation::Allegation.create(description: "new investigation for notification test")
  end

  teardown do
    allow(NotifyMailer).to receive(:investigation_updated).and_call_original
    allow(NotifyMailer).to receive(:investigation_created).and_call_original
    User.current = nil
  end

  test "should notify current owner when the owner is a person and there is any change" do
    User.current = users(:southampton)
    @investigation.update(owner: users(:southampton_steve))
    mock_investigation_updated(who_will_be_notified: [users(:southampton_steve).email])
    make_generic_change
    assert_equal @number_of_notifications, 1
  end

  test "should not notify current owner when the owner makes the change" do
    User.current = users(:southampton)
    @investigation.update(owner: teams(:southampton))
    mock_investigation_updated(who_will_be_notified: [])
    make_generic_change
    assert_equal @number_of_notifications, 0
  end

  test "should not notify anyone when the owner is a team and there is any change done by team users" do
    User.current = users(:southampton)
    @investigation.update(owner: teams(:southampton))
    mock_investigation_updated(who_will_be_notified: [])
    make_generic_change
    assert_equal @number_of_notifications, 0
  end

  test "should notify all team members when the owner is a team and there is any change done by outsiders" do
    User.current = users(:southampton)
    team_three = Team.find_by(name: "Team 3")
    @investigation.update(owner: team_three)
    mock_investigation_updated(who_will_be_notified: [users(:southampton_bob).email])
    make_generic_change
    assert_equal @number_of_notifications, 0
  end

  test "should notify creator and owner when case is closed or reopened by someone else" do
    User.current = users(:southampton)
    @investigation.update!(owner: users(:southampton), source: UserSource.new(user: users(:southampton)))
    mock_investigation_updated(who_will_be_notified: [users(:southampton), users(:southampton_bob)].map(&:email))
    @investigation.update(is_closed: !@investigation.is_closed)
    assert_equal 0, @number_of_notifications
    @investigation.update(is_closed: !@investigation.is_closed)
    assert_equal 0, @number_of_notifications
  end

  test "should not notify creator when case is closed or reopened by the creator" do
    User.current = users(:southampton)
    @investigation.update!(source: UserSource.new(user: users(:southampton)), owner: users(:southampton_bob))
    mock_investigation_updated(who_will_be_notified: [users(:southampton_bob).email])
    @investigation.update(is_closed: !@investigation.is_closed)
    assert_equal 1, @number_of_notifications
    @investigation.update(is_closed: !@investigation.is_closed)
    assert_equal 2, @number_of_notifications
  end

  test "should notify previous owner if case is owned by someone else by someone else" do
    User.current = users(:southampton)
    @investigation.update(owner: teams(:southampton))
    @investigation.update(owner: users(:southampton_bob))
    mock_investigation_updated(who_will_be_notified: [users(:southampton_bob), users(:southampton)].map(&:email))
    @investigation.update(owner: users(:southampton))
    assert_equal @number_of_notifications, 2
  end

  test "should not notify previous owner if case is owned by someone else by them" do
    User.current = users(:southampton)
    @investigation.update(owner: users(:southampton))
    mock_investigation_updated(who_will_be_notified: [users(:southampton_bob).email])
    @investigation.update(owner: users(:southampton_bob))
    assert_equal @number_of_notifications, 1
  end

  test "should notify previous owner team if case is owned by someone by someone outside" do
    User.current = users(:southampton)
    @investigation.update!(owner: users(:southampton))

    team_with_recipient_email = teams(:luton)

    @investigation.update!(owner: team_with_recipient_email)

    expected_recipients = [users(:southampton_bob).email, users(:southampton).email, team_with_recipient_email.team_recipient_email]

    mock_investigation_updated(who_will_be_notified: expected_recipients)
    @investigation.update!(owner: users(:southampton))
    assert_equal @number_of_notifications, 3
  end

  test "should not notify previous owner team if case is owned by someone by someone inside" do
    User.current = users(:southampton)
    @investigation.update(owner: users(:southampton_bob))
    @investigation.update(owner: teams(:southampton))
    mock_investigation_updated(who_will_be_notified: [users(:southampton_bob).email])
    @investigation.update(owner: users(:southampton_bob))
    assert_equal @number_of_notifications, 1
  end

  test "should notify a person who is the case owner" do
    User.current = users(:southampton)
    mock_investigation_updated(who_will_be_notified: [users(:southampton_bob).email])
    @investigation.update(owner: users(:southampton_bob))
    assert_equal @number_of_notifications, 1
  end

  test "should notify everyone in team that is the case owner" do
    User.current = users(:southampton)
    mock_investigation_updated(who_will_be_notified: teams(:southampton).users.map(&:email))
    @investigation.update(owner: teams(:southampton))
    assert_equal @number_of_notifications, 4
  end

  test "previous owner is computed correctly" do
    User.current = users(:southampton)
    @investigation.update(owner: users(:southampton))
    @investigation.update(owner: users(:southampton_steve))
    mock_investigation_updated(who_will_be_notified: [users(:southampton_bob), users(:southampton_steve)].map(&:email))
    @investigation.update(owner: users(:southampton_bob))
    assert_equal @number_of_notifications, 2
  end

  test "notifies current user when investigation created" do
    User.current = users(:southampton)
    mock_investigation_created(who_will_be_notified: [users(:southampton)])
    @investigation_two = investigations :two
    Investigation::Allegation.create(@investigation_two.attributes.merge(id: 123))
    assert_equal @number_of_notifications, 1
  end

  test "Team is notified correctly" do
    User.current = users(:southampton)
    team_with_email = teams(:luton)
    @investigation.update!(owner: teams(:luton))
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
