require "rails_helper"

RSpec.describe Investigation::Create, :with_stubbed_elasticsearch, :with_stubbed_antivirus do
  include ActiveJob::TestHelper

  let(:complainant_attributes)   { attributes_for(:complainant) }
  let(:investigation_attributes) { attributes_for(:allegation) }
  let(:user)                     { build_stubbed(:user) }
  let(:attributes) do
    investigation_attributes.tap do |attrs|
      attrs[:complainant_attributes] = complainant_attributes
    end
  end

  subject { described_class.new(attributes, user: user) }

  describe "#call" do
    describe "saves the investigation, complainant" do
      before do
        stub_request(:post, "https://api.notifications.service.gov.uk/v2/notifications/email").and_return(body: "{}")
      end

      it "saves the investigation, complainant, attachments, and send confirmation email" do
        investigation = subject.call.decorate

        expect(ActionMailer::DeliveryJob).to have_been_enqueued
          .on_queue("psd-mailers")
          .with(
            "NotifyMailer",
            "investigation_created",
            "deliver_now",
            investigation.pretty_id,
            user.name,
            user.email,
            investigation.title,
            investigation.case_type
          )

        expect(investigation).to be_persisted

        expect(Complainant.find_by(complainant_attributes)).to eq(investigation.complainant)

        expect(investigation.documents).to be_attached

        attached_blob = investigation.documents.first.blob
        expected_file_name = investigation_attributes[:documents].first.original_filename
        expect(attached_blob.filename).to eq(expected_file_name)
      end

      context "without attachment" do
        before { investigation_attributes[:documents] = [] }

        it "does not try to save an attachment" do
          investigation = subject.call

          expect(investigation).to be_persisted
          expect(investigation.documents).to_not be_attached
        end
      end

      context "without user" do
        let(:user) { nil }

        it "does not send an email" do
          subject.call

          expect(ActionMailer::DeliveryJob).to_not have_been_enqueued
        end
      end
    end
  end
end
