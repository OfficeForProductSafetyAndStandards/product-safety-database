require "rails_helper"

RSpec.describe EditPhoneCall, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus do
  include_context "with phone call correspondence setup"

  subject(:result) { described_class.call(**params) }

  let(:user_same_team) { create(:user, team: investigation.owner_team) }

  let(:params) do
    {
      user: user_same_team,
      investigation: investigation,
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
      user: user,
      investigation: investigation,
      correspondence_date: correspondence_date,
      correspondent_name: correspondent_name,
      overview: overview,
      details: details,
      phone_number: phone_number
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
        expect(activity.source.user).to eq(user_same_team)
        expect(activity.correspondence).to eq(result.correspondence)
      end

      it "notifies the relevant users", :with_test_queue_adapter do
        expect { result }.to have_enqueued_mail(NotifyMailer, :investigation_updated).with(a_hash_including(args: [
          investigation.pretty_id,
          investigation.owner_team.name,
          investigation.owner_team.email,
          "Phone call details updated on the Allegation by #{UserSource.new(user: user_same_team).show}.",
          "Allegation updated"
        ]))
      end
    end
  end
end
