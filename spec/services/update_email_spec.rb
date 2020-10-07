require "rails_helper"

RSpec.describe UpdateEmail, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus, :with_test_queue_adapter do
  let!(:investigation) { create(:allegation, creator: creator, owner_team: team, owner_user: nil) }
  let(:product) { create(:product_washing_machine) }

  let(:team) { create(:team) }

  let(:user) { create(:user) }
  let(:creator) { user }
  let(:owner) { user }

  let!(:email) do
    create(:email,
           investigation: investigation,
           correspondence_date: Date.new(2019, 1, 1),
           correspondent_name: "Mr Jones",
           details: "Please call me.",
           email_address: "jones@example.com",
           email_direction: "inbound",
           email_subject: "Re: safety issue",
           email_file: Rack::Test::UploadedFile.new("spec/fixtures/files/email.txt"),
           email_attachment: Rack::Test::UploadedFile.new("spec/fixtures/files/email_attachment.txt"))
  end

  before do
    email.email_attachment.blob.metadata[:description] = ""
    email.email_attachment.blob.save!
  end

  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      let(:result) { described_class.call(email: email) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no email parameter" do
      let(:result) { described_class.call(user: user) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with the required parameters" do
      # Default unchanged values
      let(:correspondence_date) { Date.new(2019, 1, 1) }
      let(:correspondent_name) { "Mr Jones" }
      let(:details) { "Please call me." }
      let(:email_address) { "jones@example.com" }
      let(:email_attachment) { nil }
      let(:email_direction) { "inbound" }
      let(:email_file) { nil }
      let(:email_subject) { "Re: safety issue" }
      let(:overview) { nil }
      let(:attachment_description) { "" }

      let(:result) do
        described_class.call(
          email: email,
          user: user,
          correspondence_date: correspondence_date,
          correspondent_name: correspondent_name,
          details: details,
          email_address: email_address,
          email_attachment: email_attachment,
          email_direction: email_direction,
          email_file: email_file,
          email_subject: email_subject,
          overview: overview,
          attachment_description: attachment_description
        )
      end

      let(:activity_entry) { email.investigation.activities.where(type: AuditActivity::Correspondence::EmailUpdated.to_s).order(:created_at).last }

      context "when no changes have been made" do
        it "does not generate an activity entry" do
          result
          expect(activity_entry).to be_nil
        end

        it "does not send any case updated emails" do
          expect { result }.not_to have_enqueued_mail(NotifyMailer, :investigation_updated)
        end
      end

      context "when changes have been made to the email" do
        let(:correspondence_date) { Date.new(2020, 4, 2) }
        let(:correspondent_name) { "Bob Jones" }
        let(:details) { "Please call me urgently." }
        let(:email_address) { "bob@example.com" }
        let(:email_direction) { "outbound" }
        let(:email_subject) { "Serious safety issue" }

        it "updates the email", :aggregate_failures do
          expect(result).to be_success

          expect(email.correspondence_date).to eq(Date.new(2020, 4, 2))
          expect(email.correspondent_name).to eq "Bob Jones"
          expect(email.email_subject).to eq "Serious safety issue"
          expect(email.details).to eq "Please call me urgently."
          expect(email.email_address).to eq "bob@example.com"
          expect(email.email_direction).to eq "outbound"
        end

        # rubocop:disable RSpec/ExampleLength
        it "creates an activity entry" do
          result

          expect(activity_entry.metadata).to eql({
            "email_id" => email.id,
            "updates" => {
              "correspondence_date" => %w[2019-01-01 2020-04-02],
              "correspondent_name" => ["Mr Jones", "Bob Jones"],
              "email_subject" => ["Re: safety issue", "Serious safety issue"],
              "details" => ["Please call me.", "Please call me urgently."],
              "email_address" => ["jones@example.com", "bob@example.com"],
              "email_direction" => %w[inbound outbound]
            }
          })
        end
        # rubocop:enable RSpec/ExampleLength
      end

      context "when a new email and attachment files have been uploaded" do
        let(:email_file) { Rack::Test::UploadedFile.new("spec/fixtures/files/email2.txt") }
        let(:email_attachment) { Rack::Test::UploadedFile.new("spec/fixtures/files/risk_assessment.txt") }
        let(:attachment_description) { "Risk assessment" }

        it "detaches the old file and attaches the new one", :aggregate_failures do
          expect(result).to be_success

          expect(email.email_file.filename).to eq "email2.txt"
        end

        it "creates an activity entry" do
          result

          expect(activity_entry.metadata).to eql({
            "email_id" => email.id,
            "updates" => {
              "email_filename" => ["email.txt", "email2.txt"],
              "email_attachment_filename" => ["email_attachment.txt", "risk_assessment.txt"],
              "attachment_description" => ["", "Risk assessment"]
            }
          })
        end
      end
    end
  end
end
