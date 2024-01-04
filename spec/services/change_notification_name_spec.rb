require "rails_helper"

RSpec.describe ChangeNotificationName, :with_test_queue_adapter do
  subject(:result) { described_class.call!(notification:, user_title:, user:) }

  let!(:notification) { create(:notification, user_title: previous_user_title, creator: user) }
  let(:previous_user_title) { "Case name" }
  let(:user_title) { "New case name" }
  let(:user) { create(:user, :activated) }
  let(:other_team) { create(:team) }
  let(:other_user) { create(:user, :activated, team: other_team) }

  context "with no notification parameter" do
    subject(:result) { described_class.call(user:, user_title:) }

    it "fails" do
      expect(result).to be_failure
    end
  end

  context "with no user parameter" do
    subject(:result) { described_class.call(notification:, user_title:) }

    it "fails" do
      expect(result).to be_failure
    end
  end

  context "with no user_title parameter" do
    subject(:result) { described_class.call(notification:, user:) }

    it "fails" do
      expect(result).to be_failure
    end
  end

  context "when the previous and the new name are the same" do
    subject(:result) { described_class.call!(notification:, user_title: previous_user_title, user:) }

    it "succeeds" do
      expect(result).to be_success
    end

    it "does not create a new activity" do
      expect { result }.not_to change(Activity, :count)
    end

    it "does not send an email" do
      expect { result }.not_to have_enqueued_mail(NotifyMailer, :notification_updated)
    end
  end

  context "when the previous user_title and the new user_title are different" do
    def expected_email_subject
      "Notification name updated"
    end

    def expected_email_body(name)
      "Notification name was updated by #{name}."
    end

    it "succeeds" do
      expect(result).to be_success
    end

    it "changes the user_title for the notification" do
      expect { result }.to change(notification, :user_title).from(previous_user_title).to(user_title)
    end

    it "creates a new activity for the change", :aggregate_failures do
      expect { result }.to change(Activity, :count).by(1)
      activity = notification.reload.activities.first
      expect(activity).to be_a(AuditActivity::Investigation::UpdateCaseName)
      expect(activity.added_by_user).to eq(user)
    end

    it_behaves_like "a service which notifies the notification owner", even_when_the_notification_is_closed: true
    it_behaves_like "a service which notifies the notification creator", even_when_the_notification_is_closed: true
  end
end
