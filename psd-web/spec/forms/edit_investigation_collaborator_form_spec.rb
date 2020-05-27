require "rails_helper"

RSpec.describe EditInvestigationCollaboratorForm, :with_elasticsearch, :with_stubbed_mailer do
  let!(:investigation) { create(:allegation, owner: creator) }
  let(:creator) { create(:user, :activated, team: creator_team, organisation: creator_team.organisation) }
  let(:creator_team) { create(:team) }
  let(:team) { create(:team) }

  # Use a second user to perform the change so that we can test the generic
  # investigation_updated email doesn't get sent
  let(:user) { create(:user, :activated, team: creator_team, organisation: creator_team.organisation) }

  let(:permission_level) { EditInvestigationCollaboratorForm::PERMISSION_LEVEL_DELETE }
  let(:message) { "" }
  let(:include_message) { "false" }
  let(:params_team) { team }

  let(:params) do
    {
      permission_level: permission_level,
      message: message,
      include_message: include_message,
      investigation: investigation,
      team: params_team,
      user: user
    }
  end

  let(:form) { described_class.new(params) }

  before { create(:collaboration_edit_access, investigation: investigation, collaborator: team, added_by_user: user) }

  describe "#save!" do
    context "when deleting" do
      context "when successful" do
        it "removes collaborator record" do
          expect { form.save! }.to change(Collaboration::EditAccess, :count).from(1).to(0)
        end

        it "returns true" do
          expect(form.save!).to be true
        end

        it "sends team deleted from case email", :aggregate_failures do
          form.save!

          email = delivered_emails.last
          expect(email.action_name).to eq("team_deleted_from_case_email")
          expect(email.recipient).to eq(team.team_recipient_email)
          expect(email.personalization_value(:case_id)).to eq(investigation.pretty_id)
        end

        it "does not send the generic case updated email", :aggregate_failures do
          form.save!
          expect(delivered_emails.map(&:action_name)).not_to include("investigation_updated")
        end

        context "when team has no email" do
          let(:team) { create(:team, team_recipient_email: nil) }
          let!(:team_user) { create(:user, :activated, has_viewed_introduction: true, team: team) }

          it "sends email to users" do
            form.save!

            email = delivered_emails.last
            expect(email.recipient).to eq(team_user.email)
          end
        end

        it "creates activity entry", :aggregate_failures do
          form.save!

          last_added_activity = investigation.activities.reload.order(created_at: :desc)
            .find_by!(type: "AuditActivity::Investigation::TeamDeleted")
          expect(last_added_activity.title).to eql("test team removed from allegation")
          expect(last_added_activity.source.user_id).to eql(user.id)
        end
      end

      context "when unsucessful" do
        context "when collaborator cant be found" do
          let(:params_team) { create(:team) }

          it "raises exception" do
            expect { form.save! }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end

        shared_examples "unsuccessful save" do
          it "returns false" do
            expect(form.save!).to be false
          end

          it "has proper validation message" do
            form.save!
            expect(form.errors.full_messages_for(field)).to eq([msg])
          end
        end

        context "when no email option was selected" do
          it_behaves_like "unsuccessful save" do
            let(:include_message) { nil }
            let(:msg) { "Select whether you want to include a message" }
            let(:field) { :include_message }
          end
        end

        context "when no message was written" do
          it_behaves_like "unsuccessful save" do
            let(:include_message) { "true" }
            let(:msg) { "Enter a message to the team" }
            let(:field) { :message }
          end
        end

        context "when no collaborator option was selected" do
          it_behaves_like "unsuccessful save" do
            let(:permission_level) { nil }
            let(:msg) { "Select the permission level the team should have" }
            let(:field) { :permission_level }
          end
        end

        context "when existing collaborator option was selected" do
          it_behaves_like "unsuccessful save" do
            let(:permission_level) { EditInvestigationCollaboratorForm::PERMISSION_LEVEL_EDIT }
            let(:msg) { "This team already has this permission level. Select a different option or return to the case." }
            let(:field) { :permission_level }
          end
        end
      end
    end
  end
end
