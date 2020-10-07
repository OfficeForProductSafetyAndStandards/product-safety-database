require "rails_helper"

RSpec.describe AddEmailToCase, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus do
  # Create the case before running tests so that we can check which emails are sent by the service
  let!(:investigation) { create(:allegation, creator: creator, owner_team: team, owner_user: nil) }
  let(:product) { create(:product_washing_machine) }

  let(:team) { create(:team) }

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

      it "notifies the team", :aggregate_failures do
        result
        email = delivered_emails.last
        expect(email.recipient).to eq(team.email)
        expect(email.action_name).to eq("investigation_updated")
      end
    end

    context "with an email file and an attachment" do
      let(:result) do
        described_class.call(
          investigation: investigation,
          user: user,
          correspondence_date: Date.new(2020, 1, 2),
          email_subject: "",
          details: "",
          email_file: Rack::Test::UploadedFile.new("spec/fixtures/files/email.txt"),
          email_attachment: Rack::Test::UploadedFile.new("spec/fixtures/files/risk_assessment.txt"),
          attachment_description: "Risk assessment"
        )
      end

      it "attaches the files", :aggregate_failures do
        expect(result).to be_success

        expect(result.email.email_file.attached?).to be true
        expect(result.email.email_file.filename).to eq "email.txt"

        expect(result.email.email_attachment.attached?).to be true
        expect(result.email.email_attachment.filename).to eq "risk_assessment.txt"
        expect(result.email.email_attachment.metadata).to include({ description: "Risk assessment" })
      end
    end
  end
end
