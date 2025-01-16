require "rails_helper"

RSpec.describe SendReminderEmailDraftNotificationsJob, :with_stubbed_antivirus, :with_stubbed_mailer, type: :job do
  let(:user) { create(:user) }
  let(:draft) { create_notification(state: "draft", updated_at: 75.days.ago, pretty_id: "2024-0002") }
  let(:mailer) { instance_double(ActionMailer::MessageDelivery) }

  before do
    allow(Flipper).to receive(:enabled?).with(:submit_notification_reminder).and_return(true)
    allow(NotifyMailer).to receive(:send_email_reminder).and_return(mailer)
    allow(mailer).to receive(:deliver_later)
  end

  describe "#perform" do
    context "when the Flipper feature is enabled" do
      it "calls send_reminder_emails" do
        job = described_class.new
        allow(job).to receive(:send_reminder_emails)
        job.perform
        expect(job).to have_received(:send_reminder_emails)
      end
    end

    context "when the Flipper feature is disabled" do
      before do
        allow(Flipper).to receive(:enabled?).with(:submit_notification_reminder).and_return(false)
      end

      it "does not call send_reminder_emails" do
        job = described_class.new
        allow(job).to receive(:send_reminder_emails)
        job.perform
        expect(job).not_to have_received(:send_reminder_emails)
      end
    end
  end

  describe "#send_reminder_emails" do
    before do
      draft # Trigger creation of the draft
    end

    it "fetches drafts and sends emails" do
      allow(NotifyMailer).to receive(:send_email_reminder)
      described_class.new.send(:send_reminder_emails)
      expect(NotifyMailer).to have_received(:send_email_reminder)
    end

    it "logs an error if an exception occurs" do
      job = described_class.new
      allow(job).to receive(:fetch_drafts).and_raise(StandardError, "Test error")
      allow(Rails.logger).to receive(:error)
      expect {
        job.send(:send_reminder_emails)
      }.not_to raise_error
      expect(Rails.logger).to have_received(:error).with(/Failed to send reminder emails for drafts days old due to: Test error/)
    end
  end

  describe "#fetch_drafts" do
    it "fetches drafts matching the criteria" do
      draft
      drafts = described_class.new.send(:fetch_drafts, 75)
      expect(drafts).to include(draft)
    end
  end

  describe "#send_mails" do
    context "when the draft has a valid user" do
      before do
        draft # Trigger creation of the draft
      end

      it "sends the final reminder email with the correct details" do
        allow(NotifyMailer).to receive(:send_email_reminder).and_return(mailer)
        described_class.new.send(:send_mails, [draft], 87, 3, true, "This will be the final reminder before the notification will be automatically deleted in 3 days, if the status remains on 'Draft'.")
        expect(NotifyMailer).to have_received(:send_email_reminder).with(
          user: user, remaining_days: 3, last_reminder: true, last_line: "This will be the final reminder before the notification will be automatically deleted in 3 days, if the status remains on 'Draft'.",
          days: 87, title: draft.user_title, pretty_id: draft.pretty_id
        )
      end
    end
  end

  describe "#reminder_last_line" do
    it "returns the final reminder text if last_reminder is true" do
      line = described_class.new.send(:reminder_last_line, true)
      expect(line).to eq("This will be the final reminder before the notification will be automatically deleted in 3 days, if the status remains on 'Draft'.")
    end

    it "returns the regular reminder text if last_reminder is false" do
      line = described_class.new.send(:reminder_last_line, false)
      expect(line).to eq("If the status of this notification remains in 'Draft', another reminder email will be sent in the next coming days.")
    end
  end

  def create_notification(state:, updated_at:, pretty_id:)
    notification = build(:notification, state:, updated_at:, pretty_id:)
    notification.build_creator_user_collaboration(collaborator: user)
    notification.save!(validate: false)
    notification
  end
end
