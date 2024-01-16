require "rails_helper"

RSpec.describe PhoneCallCorrespondenceForm do
  subject(:form) { described_class.new(params) }

  include_context "with phone call correspondence setup"

  let(:existing_transcript_file_id) { nil }
  let(:correspondence_date) { { "day" => day, "month" => "1", "year" => "2020" } }
  let(:day) { "1" }

  before do
    params[:existing_transcript_file_id] = existing_transcript_file_id
  end

  describe ".from", :with_stubbed_antivirus, :with_stubbed_mailer do
    let(:correspondence_date) { Date.current }
    let(:phone_call) { AddPhoneCallToNotification.call!(investigation:, user:, **params).correspondence }

    it "creates a valid form object" do
      expect(described_class.from(phone_call))
        .to have_attributes(
          correspondence_date: DateParser.new(correspondence_date).date,
          correspondent_name:, phone_number:, overview:,
          details:, transcript: phone_call.transcript, id: phone_call.id
        )
    end

    context "when no transcript added to the correspondence" do
      let(:transcript) { nil }

      it "creates a valid form object" do
        expect(described_class.from(phone_call))
          .to have_attributes(
            correspondence_date: DateParser.new(correspondence_date).date,
            correspondent_name:, phone_number:, overview:,
            details:, transcript: phone_call.transcript, id: phone_call.id
          )
      end
    end
  end

  describe "validations" do
    it "has a valid test set up" do
      expect(form).to be_valid
    end

    it_behaves_like "it does not allow an incomplete", :correspondence_date
    it_behaves_like "it does not allow malformed dates", :correspondence_date
    it_behaves_like "it does not allow dates in the future", :correspondence_date
    it_behaves_like "it does not allow far away dates", :correspondence_date, nil, on_or_before: false

    describe "#validate_transcript_and_content" do
      context "when no transcript is uploaded" do
        let(:transcript) { nil }

        it { is_expected.to be_valid }

        context "when no overview provided" do
          let(:overview) { nil }

          it "is invalid and has a descriptive error", aggregate_failures: true do
            expect(form).to be_invalid
            expect(form.errors.full_messages_for(:base)).to eq(["Please provide either a transcript or complete the summary and notes fields"])
          end
        end

        context "when no details is provided", aggregate_failures: true do
          let(:details) { nil }

          it "is invalid and has a descriptive error", aggregate_failures: true do
            expect(form).to be_invalid
            expect(form.errors.full_messages_for(:base)).to eq(["Please provide either a transcript or complete the summary and notes fields"])
          end
        end
      end
    end

    describe "#cache_file!" do
      context "when a transcript file is not provided" do
        let(:transcript) { nil }

        it "does not create a blob" do
          expect { form.cache_file! }.not_to change(ActiveStorage::Blob, :count)
        end
      end

      context "when a transcript file is provided" do
        it "does not create a blob" do
          expect { form.cache_file! }.to change(ActiveStorage::Blob, :count).by(1)
        end

        it "set existing_transcript_file_id" do
          expect { form.cache_file! }.to change(form, :existing_transcript_file_id).from(nil).to(instance_of(String))
        end
      end
    end

    describe "#load_transcript_file " do
      let(:previous_form) do
        described_class.new(params.merge(transcript: Rack::Test::UploadedFile.new(file_fixture("phone_call_transcript.txt"))))
      end

      before do
        previous_form.cache_file!
      end

      context "when no transcript is uploaded" do
        let(:transcript) { nil }

        it "does not set the transcript" do
          expect { form.load_transcript_file }.not_to change(form, :transcript)
        end

        context "when no new transcript has been uploaded" do
          before do
            params[:existing_transcript_file_id] = previous_form.existing_transcript_file_id
          end

          it "loads the file blob" do
            expect { form.load_transcript_file }
              .to change(form, :transcript).from(nil).to(instance_of(ActiveStorage::Blob))
          end
        end
      end
    end
  end
end
