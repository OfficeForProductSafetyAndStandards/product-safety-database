require "rails_helper"

RSpec.describe UpdateCorrectiveAction, :with_stubbed_mailer, :with_stubbed_antivirus, :with_test_queue_adapter do
  include ActionDispatch::TestProcess::FixtureFile
  subject(:result) do
    described_class.call(
      corrective_action_attributes
        .merge(corrective_action:, user:, changes:)
    )
  end

  include_context "with corrective action setup for updates"

  let(:user)             { create(:user, :activated) }
  let(:case_creator)     { create(:user, :activated, team: user.team) }
  let(:investigation)    { create(:allegation, creator: case_creator) }
  let(:editor_team)      do
    create(:team).tap do |t|
      AddTeamToNotification.call!(
        notification: investigation,
        team: t,
        collaboration_class: Collaboration::Access::Edit,
        user:
      )
    end
  end
  let(:case_editor)               { create(:user, :activated, team: editor_team) }
  let!(:corrective_action)        { create(:corrective_action, :with_file, investigation:, investigation_product:, business:) }
  let(:corrective_action_form)    { CorrectiveActionForm.from(corrective_action) }
  let(:corrective_action_attributes) do
    corrective_action_form.tap { |form|
      form.assign_attributes(
        date_decided: new_date_decided,
        other_action: new_other_action,
        action: new_summary,
        investigation_product_id: corrective_action.investigation_product_id,
        measure_type: new_measure_type,
        legislation: new_legislation,
        has_online_recall_information: new_has_online_recall_information,
        online_recall_information: new_online_recall_information,
        geographic_scopes: new_geographic_scopes,
        duration: new_duration,
        details: new_details,
        business_id: corrective_action.business_id,
        existing_document_file_id:,
        related_file:,
        file: file_form
      )
    }.serializable_hash
  end
  let(:changes) { corrective_action_form.changes }

  describe "#call" do
    context "with no parameters" do
      it "returns a failure" do
        expect(described_class.call).to be_failure
      end
    end

    context "when missing parameters" do
      let(:params) do
        {
          corrective_action:,
          user:,
          file: { description: new_file_description }
        }
      end

      it { expect(described_class.call(params.except(:corrective_action))).to be_a_failure }
      it { expect(described_class.call(params.except(:user))).to be_a_failure }
    end

    context "with the required parameters" do
      context "when no changes have been made" do
        let(:related_file)                      { false }
        let(:new_date_decided)                  { corrective_action.date_decided }
        let(:new_file_description)              { corrective_action.document.metadata["description"] }
        let(:new_document)                      { nil }
        let(:file_form)                         { {} }
        let(:existing_document_file_id)         { corrective_action.document_blob&.signed_id }
        let(:new_summary)                       { corrective_action.action }
        let(:new_other_action)                  { corrective_action.other_action }
        let(:new_geographic_scopes)             { corrective_action.geographic_scopes }
        let(:new_duration)                      { corrective_action.duration }
        let(:new_measure_type)                  { corrective_action.measure_type }
        let(:new_legislation)                   { corrective_action.legislation }
        let(:new_details)                       { corrective_action.details }
        let(:new_has_online_recall_information) { corrective_action.has_online_recall_information }
        let(:new_online_recall_information)     { corrective_action.online_recall_information }

        shared_examples "it does not create an audit log" do
          specify { expect { result }.not_to change(corrective_action.investigation.activities.where(type: "AuditActivity::CorrectiveAction::Update"), :count) }
        end

        it "does not change corrective action" do
          expect { result }.not_to change(corrective_action, :attributes)
        end

        context "with document attached" do
          let(:related_file) { true }
          let(:file_form) { { description: corrective_action.document_blob.metadata.fetch(:description) } }

          it "does not change the attached document" do
            expect { result }.not_to change(corrective_action, :document)
          end

          it "does not change the attached document's metadata" do
            expect { result }.not_to change(corrective_action.document, :metadata)
          end

          include_examples "it does not create an audit log"
        end

        context "with no document attached" do
          before do
            corrective_action.document.detach
            corrective_action.reload
          end

          it "does not change the attached document's" do
            expect { result }.not_to change(corrective_action, :document)
          end

          include_examples "it does not create an audit log"
        end
      end

      context "when changes have been made" do
        it "updates the corrective action" do
          expect {
            result
          }.to change(corrective_action, :date_decided).from(corrective_action.date_decided).to(new_date_decided)
        end

        it "generates an activity entry with the changes" do
          result

          activity_timeline_entry = investigation.activities.reload.order(:created_at).find_by!(type: "AuditActivity::CorrectiveAction::Update")
          expect(activity_timeline_entry).to have_attributes({})
        end

        def expected_email_subject
          "Corrective action edited for notification"
        end

        def expected_email_body(name)
          "#{name} edited a corrective action on the notification."
        end

        it_behaves_like "a service which notifies the investigation owner"

        context "when removing the previously attached file" do
          let(:related_file) { false }

          it "removes the related file" do
            expect { result }
              .to change(corrective_action.reload.document, :attached?).from(true).to(false)
          end

          it "creates an audit log" do
            expect { result }
              .to change(investigation.activities.where(type: "AuditActivity::CorrectiveAction::Update"), :count).from(0).to(1)
          end
        end
      end
    end

    context "with no previously attached file" do
      let(:related_file) { true }

      before { corrective_action.document.detach }

      it "stored the new file with the description", :aggregate_failures do
        result

        document = corrective_action.reload.document
        expect(document.filename.to_s).to eq("corrective_action.txt")
        expect(document.metadata[:description]).to eq(File.basename(new_file_description))
      end

      context "when not adding a new file" do
        let(:file_form) { {} }

        it "stored the new file with the description", :aggregate_failures do
          expect { result }.not_to raise_error
        end
      end
    end

    context "with a new file" do
      let(:related_file) { true }

      it "stored the new file with the description", :aggregate_failures do
        result

        document = corrective_action.reload.document
        expect(document.filename.to_s).to eq("corrective_action.txt")
        expect(document.metadata[:description]).to eq(new_file_description)
      end
    end

    context "without a new file" do
      let(:new_document) { nil }
      let(:related_file) { false }

      it "stored the new file with the description", :aggregate_failures do
        expect {
          result
        }.not_to change(corrective_action, :document)
      end
    end
  end
end
