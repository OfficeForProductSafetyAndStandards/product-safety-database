require "rails_helper"

RSpec.describe PhoneCallCorrespondenceForm do
  include ActionDispatch::TestProcess::FixtureFile

  subject(:form) { described_class.new(params) }

  let(:params) {
    {
      correspondence_date: correspondence_date,
      correspondent_name: Faker::Name.name,
      phone_number: Faker::PhoneNumber.phone_number,
      overview: overview,
      details: details,
      transcript: transcript,
      existing_transcript_file_id: existing_transcript_file_id
    }
  }
  let(:existing_transcript_file_id) { nil }
  let(:transcript) { Rack::Test::UploadedFile.new(file_fixture("files/phone_call_transcript.txt")) }
  let(:overview) { Faker::Hipster.paragraph }
  let(:details) { Faker::Hipster.paragraph }
  let(:correspondence_date) { { "day" => day, "month" => "1", "year" => "2020" } }
  let(:day) { "1" }

  describe "validations" do
    it "has a valid test set up" do
      expect(form).to be_valid
    end

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
          expect { form.cache_file! }.not_to change { ActiveStorage::Blob.count }
        end
      end

      context "when a transcript file is provided" do
        it "does not create a blob" do
          expect { form.cache_file! }.to change { ActiveStorage::Blob.count }.by(1)
        end

        it "set existing_transcript_file_id" do
          expect { form.cache_file! }.to change(form, :existing_transcript_file_id).from(nil).to(instance_of(String))
        end
      end
    end

    describe "#load_transcript_file " do
      let(:previous_form) do
        described_class.new(params.merge(transcript: Rack::Test::UploadedFile.new(file_fixture("files/phone_call_transcript.txt"))))
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
