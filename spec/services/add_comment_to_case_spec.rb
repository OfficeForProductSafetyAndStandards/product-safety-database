require "rails_helper"

RSpec.describe AddCommentToCase, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_test_queue_adapter do
  # Create the case before running tests so that we can check which emails are sent by the service
  let!(:investigation) { create(:allegation, creator: user) }
  let(:user) { create(:user) }
  let(:body) { "Very important note" }

  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      let(:result) { described_class.call(investigation: investigation) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no investigation parameter" do
      let(:result) { described_class.call(user: user) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with required parameters" do
      def expected_email_subject
        "Allegation updated"
      end

      def expected_email_body(name)
        "Comment was added to the #{investigation.case_type} by #{name}."
      end

      let(:assessment_date) { Time.zone.today }

      let(:result) do
        described_class.call(
          user: user,
          investigation: investigation,
          body: body
        )
      end

      it "succeeds" do
        expect(result).to be_a_success
      end

      it "adds an audit activity record", :aggregate_failures do
        result
        last_added_activity = investigation.activities.order(:id).first
        byebug
        expect(last_added_activity).to be_a(CommentActivity)
        expect(last_added_activity.body).to eql(body)
      end

      it_behaves_like "a service which notifies the case owner"
    end
  end
end
