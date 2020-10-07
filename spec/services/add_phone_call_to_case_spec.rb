require "rails_helper"

RSpec.describe AddPhoneCallToCase, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus do
  include ActionDispatch::TestProcess::FixtureFile

  subject(:result) { described_class.call(params) }

  let(:user)                { create :user }
  let(:investigation)       { create :allegation }
  let(:phone_number)        { Faker::PhoneNumber.phone_number }
  let(:correspondence_date) { Date.parse("1-1-2020") }
  let(:correspondent_name)  { Faker::Name.name }
  let(:overview)            { Faker::Hipster.paragraph }
  let(:details)             { Faker::Hipster.paragraph }
  let(:params) do
    {
      investigation: investigation,
      user: user,
      transcript: Rack::Test::UploadedFile.new(file_fixture("files/phone_call_transcript.txt")),
      correspondence_date: correspondence_date,
      phone_number: phone_number,
      correspondent_name: correspondent_name,
      overview: overview,
      details: details
    }
  end

  describe "#call" do
    context "when no investigation is provided" do
      let(:investigation) { nil }

      it { expect(result).to be_a_failure }
      it { expect(result.error).to eq("No investigation supplied") }
    end

    context "when no user is provided" do
      let(:user) { nil }

      it { expect(result).to be_a_failure }
      it { expect(result.error).to eq("No user supplied") }
    end
  end

  describe "when providing all necessary arguments" do
    it "creates a correspondence" do
      expect(result.correspondence).to have_attributes(
        transcript: instance_of(ActiveStorage::Attached::One),
        correspondence_date: correspondence_date,
        correspondent_name: correspondent_name,
        overview: overview,
        details: details
      )
    end

    it "creates an audit log" do
      expect(result.correspondence.activity).to have_attributes(
        body: "Call with: **#{correspondent_name}** (#{phone_number})<br>Date: **01/01/2020**<br>Attached: phone\\_call\\_transcript.txt<br><br>#{details}",
        investigation_id: investigation.id)
      expect(result.correspondence.activity.title).to eq(overview)
    end
  end
end
