require "rails_helper"

RSpec.describe AddCommentToNotification, :with_test_queue_adapter do
  # Create the case before running tests so that we can check which emails are sent by the service
  let!(:notification) { create(:notification, creator:, owner_team: team, owner_user: nil) }
  let(:product) { create(:product_washing_machine) }

  let(:team) { create(:team) }
  let(:business) { create(:business) }

  let(:read_only_teams) { [team] }
  let(:user) { create(:user) }
  let(:creator) { user }
  let(:owner) { user }
  let(:body) { "an important note" }

  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      let(:result) { described_class.call(notification:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no notification parameter" do
      let(:result) { described_class.call(user:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with required parameters" do
      def expected_email_subject
        "Notification updated"
      end

      def expected_email_body(name)
        "#{name} commented on the notification."
      end

      let(:assessment_date) { Time.zone.today }

      let(:result) do
        described_class.call(
          user:,
          notification:,
          body:
        )
      end

      it "succeeds" do
        expect(result).to be_a_success
      end

      it "adds an audit activity record", :aggregate_failures do
        result
        last_added_activity = notification.activities.order(:id).first
        expect(last_added_activity).to be_a(AuditActivity::Investigation::AddComment)
        expect(last_added_activity.metadata["comment_text"]).to eql(body)
      end

      it_behaves_like "a service which notifies the notification owner"
    end
  end
end
