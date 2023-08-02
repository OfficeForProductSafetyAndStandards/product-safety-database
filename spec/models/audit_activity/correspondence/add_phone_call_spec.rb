require "rails_helper"

RSpec.describe AuditActivity::Correspondence::AddPhoneCall, :with_stubbed_mailer, :with_stubbed_antivirus do
  subject(:activity) { described_class.new(metadata:) }

  let(:phone_call) { create(:correspondence_phone_call) }
  let(:metadata) { described_class.build_metadata(phone_call) }

  describe ".build_metadata" do
    it "returns a Hash of attributes" do
      expect(metadata).to eq({
        "correspondence" => phone_call.attributes.merge(
          "transcript" => phone_call.transcript.blob.attributes
        )
      })
    end
  end

  describe "#title" do
    it "returns the title" do
      expect(activity.title).to eq phone_call.overview
    end
  end

  describe "#correspondent_name" do
    it "returns the correspondent name" do
      expect(activity.correspondent_name).to eq phone_call.correspondent_name
    end
  end

  describe "#correspondence_date" do
    it "returns the correspondence date" do
      expect(activity.correspondence_date).to eq phone_call.correspondence_date
    end
  end

  describe "#phone_number" do
    it "returns the phone number" do
      expect(activity.phone_number).to eq phone_call.phone_number
    end
  end

  describe "#filename" do
    it "returns the filename" do
      expect(activity.filename).to eq phone_call.transcript_blob.filename.to_s
    end
  end

  describe "#details" do
    it "returns the details" do
      expect(activity.details).to eq phone_call.details
    end
  end
end
