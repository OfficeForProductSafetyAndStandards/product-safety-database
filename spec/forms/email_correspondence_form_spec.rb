require "rails_helper"

RSpec.describe EmailCorrespondenceForm, :with_stubbed_mailer do
  subject(:form) do
    described_class.new(
      attachment_description:,
      correspondence_date:,
      correspondent_name:,
      details:,
      email_address:,
      email_attachment:,
      email_direction:,
      email_file:,
      email_subject:,
      email_attachment_id:,
      email_file_id:,
      overview:,
      "correspondence_date(1i)" => 2020,
      "correspondence_date(2i)" => 1,
      "correspondence_date(3i)" => 20
    )
  end

  let(:attachment_description) { "" }
  let(:correspondence_date) { Date.new(2020, 1, 20) }
  let(:correspondent_name) { "" }
  let(:details) { "" }
  let(:email_address) { "" }
  let(:email_attachment) { nil }
  let(:email_direction) { nil }
  let(:email_file) { nil }
  let(:email_subject) { "" }
  let(:email_attachment_id) { nil }
  let(:email_file_id) { nil }
  let(:overview) { nil }

  describe "validations" do
    context "when a correspondence date is missing" do
      let(:correspondence_date) { nil }

      it "is not valid and contains an error message", :aggregate_failures do
        expect(form).not_to be_valid
        expect(form.errors.details[:correspondence_date]).to eq([{ error: :blank }])
      end
    end

    it_behaves_like "it does not allow an incomplete", :correspondence_date
    it_behaves_like "it does not allow malformed dates", :correspondence_date
    it_behaves_like "it does not allow dates in the future", :correspondence_date
    it_behaves_like "it does not allow far away dates", :correspondence_date, nil, on_or_before: false

    context "when both subject and body and email file are missing" do
      let(:email_file) { nil }
      let(:email_subject) { "" }
      let(:details) { "" }

      it "is not valid and contains an error message", :aggregate_failures do
        expect(form).not_to be_valid
        expect(form.errors.details[:base]).to eq([{ error: "Please provide either an email file or a subject and body" }])
      end
    end

    context "when just a date, subject and body are specified" do
      let(:email_subject) { "Re: safety issue" }
      let(:details) { "Please call us about this issue." }
      let(:email_file) { nil }

      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "when just a date and email file are specified" do
      let(:email_subject) { "" }
      let(:details) { "" }
      let(:email_file) { Rack::Test::UploadedFile.new("spec/fixtures/files/email.txt") }

      it "is valid" do
        expect(form).to be_valid
      end
    end
  end
end
