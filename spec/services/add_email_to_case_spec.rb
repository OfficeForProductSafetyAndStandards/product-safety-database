require "rails_helper"

RSpec.describe AddEmailToCase, :with_stubbed_elasticsearch, :with_test_queue_adapter do
  let(:investigation) { create(:allegation, creator: creator) }
  let(:product) { create(:product_washing_machine) }

  let(:user) { create(:user) }
  let(:creator) { user }
  let(:owner) { user }

  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no investigation parameter" do
      let(:result) do
        described_class.call(
          user: user
        )
      end

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      let(:result) do
        described_class.call(
          investigation: investigation
        )
      end

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with the minimum required parameters" do
      let(:result) do
        described_class.call(
          investigation: investigation,
          user: user,
          correspondence_date: Date.new(2020, 1, 2),
          email_subject: "Re: safety issue",
          details: "Please call me."
        )
      end

      it "succeeds" do
        expect(result).to be_success
      end

      it "adds an email to the case with the details given", :aggregate_failures do
        result
        email = investigation.emails.first
        expect(email).not_to be_nil
        expect(email.email_subject).to eq "Re: safety issue"
        expect(email.correspondence_date).to eq Date.new(2020, 1, 2)
        expect(email.details).to eq "Please call me."
      end

      it "creates an audit activity", :aggregate_failures do
        result
        activity = investigation.reload.activities.first
        expect(activity).to be_a(AuditActivity::Correspondence::AddEmail)
        expect(activity.product).to be_nil
        expect(activity.title(nil)).to be_nil
        expect(activity.body).to eq "Subject: **Re: safety issue**<br>Date sent: **02/01/2020**<br><br>Please call me."
        expect(activity.metadata).to be_nil
      end
    end
  end
end
