RSpec.shared_examples "a service which notifies the investigation creator", :with_test_queue_adapter do |even_when_the_investigation_is_closed: false|
  let!(:investigation) { create(:enquiry, is_closed: false, creator: creator_user) }

  context "when the user is the investigation creator" do
    let(:creator_user) { user }

    it "does not send an email" do
      expect { result }.not_to have_enqueued_mail(NotifyMailer, :investigation_updated)
    end
  end

  context "when the user is not the investigation creator" do
    let(:creator_user) { create(:user, :activated, team: user.team, organisation: user.organisation) }

    it "sends an email to the user" do
      expect { result }.to have_enqueued_mail(NotifyMailer, :investigation_updated).with(
        investigation.pretty_id,
        creator_user.name,
        creator_user.email,
        expected_email_body(user.name),
        expected_email_subject
      )
    end

    unless even_when_the_investigation_is_closed
      context "when the investigation is closed" do
        before { ChangeNotificationStatus.call!(notification: investigation, user:, new_status: "closed") }

        it "does not send an email" do
          expect { result }.not_to have_enqueued_mail(NotifyMailer, :investigation_updated)
        end
      end
    end
  end
end

RSpec.shared_examples "a service which notifies the notification creator", :with_test_queue_adapter do |even_when_the_notification_is_closed: false|
  let!(:notification) { create(:notification, is_closed: false, creator: creator_user) }

  context "when the user is the notification creator" do
    let(:creator_user) { user }

    it "does not send an email" do
      expect { result }.not_to have_enqueued_mail(NotifyMailer, :investigation_updated)
    end
  end

  context "when the user is not the notification creator" do
    let(:creator_user) { create(:user, :activated, team: user.team, organisation: user.organisation) }

    it "sends an email to the user" do
      expect { result }.to have_enqueued_mail(NotifyMailer, :investigation_updated).with(
        notification.pretty_id,
        creator_user.name,
        creator_user.email,
        expected_email_body(user.name),
        expected_email_subject
      )
    end

    unless even_when_the_notification_is_closed
      context "when the notification is closed" do
        before { ChangeNotificationStatus.call!(notification:, user:, new_status: "closed") }

        it "does not send an email" do
          expect { result }.not_to have_enqueued_mail(NotifyMailer, :investigation_updated)
        end
      end
    end
  end
end
