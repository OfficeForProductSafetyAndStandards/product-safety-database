require "rails_helper"

RSpec.describe UpdateEmail, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus, :with_test_queue_adapter do
  let!(:investigation) { create(:allegation, creator: creator, owner_team: team, owner_user: nil) }
  let(:product) { create(:product_washing_machine) }

  let(:team) { create(:team) }

  let(:user) { create(:user) }
  let(:creator) { user }
  let(:owner) { user }

  let(:email) { create(:email, investigation: investigation) }

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
        )
      end

      context "when changes have been made" do
        let(:correspondence_date) { Date.new(2020, 4, 2) }
        let(:correspondent_name) { "Bob Jones" }
        let(:details) { "Please call me urgently." }
        let(:email_address) { "bob@example.com" }
        let(:email_attachment) { nil }
        let(:email_direction) { "outbound" }
        let(:email_file) { nil }
        let(:email_subject) { "Serious safety issue" }
        let(:overview) { nil }

        it "updates the email", :aggregate_failures do
          expect(result).to be_success

          expect(email.correspondence_date).to eq(Date.new(2020, 4, 2))
          expect(email.correspondent_name).to eq "Bob Jones"
          expect(email.email_subject).to eq "Serious safety issue"
          expect(email.details).to eq "Please call me urgently."
          expect(email.email_address).to eq "bob@example.com"
          expect(email.email_direction).to eq "outbound"
        end
      end
    end
  end
end
