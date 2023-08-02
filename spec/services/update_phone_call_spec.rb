require "rails_helper"

RSpec.describe UpdatePhoneCall, :with_stubbed_mailer, :with_stubbed_antivirus do
  subject(:result) { described_class.call(**params) }

  include_context "with phone call correspondence setup"

  let(:user_same_team) { create(:user, team: investigation.owner_team) }

  let(:params) do
    {
      user: user_same_team,
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

  let!(:phone_call) do
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

  describe "#call" do
    context "when no user was supplied" do
      let(:user_same_team) { nil }

      it "fails with the appropriate error", :aggregate_failures do
        expect(result).to be_a_failure
        expect(result.error).to eq("No user supplied")
      end
    end

    context "when no phone call correspondence was supplied" do
      let(:phone_call) { nil }

      it "fails with the appropriate error", :aggregate_failures do
        expect(result).to be_a_failure
        expect(result.error).to eq("No phone call supplied")
      end
    end

    context "when non of attributes has changed" do
      let(:transcript) { phone_call.transcript_blob }

      let(:params) do
        {
          user: user_same_team,
          investigation:,
          correspondence: phone_call,
          correspondence_date:,
          correspondent_name:,
          phone_number:,
          transcript:,
          overview:,
          details:
        }
      end

      context "when the transcript has not changed" do
        it "does not change the phone call" do
          expect { result }.not_to change(phone_call, :reload)
        end

        it "does not change the phone call transcript" do
          expect { result }.not_to change(phone_call, :transcript_blob)
        end

        it "does not create an audit log" do
          expect { result }.not_to change(AuditActivity::Correspondence::PhoneCallUpdated, :count)
        end
      end

      context "when the transcript has changed" do
        let(:new_file) { Rack::Test::UploadedFile.new(new_transcript) }
        let(:transcript) do
          ActiveStorage::Blob.create_and_upload!(
            io: new_file,
            filename: new_file.original_filename,
            content_type: new_file.content_type
          )
        end

        it "does not change the phone call" do
          expect { result }.not_to change(phone_call, :reload)
        end

        it "does create an audit log" do
          expect { result }.to change(AuditActivity::Correspondence::PhoneCallUpdated, :count)
        end
      end
    end

    context "when supplied with the correct informations" do
      it "updates the correspondence", :aggregate_failures do
        expect(result.correspondence)
          .to have_attributes(
            correspondent_name: new_correspondent_name, correspondence_date: new_correspondence_date,
            phone_number: new_phone_number, overview: new_overview, details: new_details
          )

        expect(result.correspondence.transcript_blob.filename.to_s).to eq(new_transcript.basename.to_s)
      end

      it "creates an audit log", :aggregate_failures do
        result
        activity = result.correspondence.activities.find_by!(type: "AuditActivity::Correspondence::PhoneCallUpdated")

        expect(activity.investigation).to eq(investigation)
        expect(activity.added_by_user).to eq(user_same_team)
        expect(activity.correspondence).to eq(result.correspondence)
      end

      describe "notifications" do
        context "with a team email" do
          it "notifies the relevant users", :with_test_queue_adapter do
            expect { result }.to have_enqueued_mail(NotifyMailer, :investigation_updated).with(
              investigation.pretty_id,
              investigation.owner_team.name,
              investigation.owner_team.email,
              "Phone call details updated on the Case by #{user_same_team.decorate.display_name(viewer: user_same_team)}.",
              "Case updated"
            )
          end
        end

        context "with no team email" do
          let(:team_recipient_email) { nil }

          it "notifies the relevant users", :with_test_queue_adapter do
            expect { result }.to have_enqueued_mail(NotifyMailer, :investigation_updated).with(
              investigation.pretty_id,
              investigation.owner_user.name,
              investigation.owner_user.email,
              "Phone call details updated on the Case by #{user_same_team.decorate.display_name(viewer: user_same_team)}.",
              "Case updated"
            )
          end
        end
      end
    end
  end
end
