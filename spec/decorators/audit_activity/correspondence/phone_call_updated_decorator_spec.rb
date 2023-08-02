require "rails_helper"

RSpec.describe AuditActivity::Correspondence::PhoneCallUpdatedDecorator, :with_stubbed_mailer, :with_stubbed_antivirus do
  subject(:decorator) { phone_call.activities.find_by!(type: "AuditActivity::Correspondence::PhoneCallUpdated").decorate }

  include_context "with phone call correspondence setup"

  let(:phone_call) do
    AddPhoneCallToCase.call!(
      user:,
      investigation:,
      correspondence_date:,
      correspondent_name:,
      overview:,
      details:,
      phone_number:
    ).correspondence
  end

  let(:params) do
    {
      user:,
      investigation:,
      correspondence: phone_call,
      correspondence_date: new_correspondence_date,
      correspondent_name: new_correspondent_name,
      phone_number: new_phone_number,
      transcript: Rack::Test::UploadedFile.new(new_transcript),
      overview: new_overview,
      details: new_details
    }
  end

  before { UpdatePhoneCall.call!(**params) }

  describe "#new_correspondent_name" do
    it "returns the new value" do
      expect(decorator.new_correspondent_name).to eq(new_correspondent_name)
    end

    include_examples "with removed field", :correspondent_name
  end

  describe "#new_phone_number" do
    it "returns the new value" do
      expect(decorator.new_phone_number).to eq(new_phone_number)
    end

    include_examples "with removed field", :phone_number
  end

  describe "#new_summary" do
    it "returns the new value" do
      expect(decorator.new_summary).to eq(new_overview)
    end

    include_examples "with removed field", :summary, :overview
  end

  describe "#new_notes" do
    it "returns the new value" do
      expect(decorator.new_notes).to eq(new_details)
    end

    include_examples "with removed field", :notes, :details
  end
end
