require "rails_helper"

RSpec.describe DeleteTeam, :with_stubbed_mailer, :with_stubbed_elasticsearch do
  let(:team) { create(:team) }
  let(:new_team) { create(:team) }

  let(:team_user) { create(:user, :activated, :team_admin, team: team, organisation: team.organisation) }
  let(:new_team_user) { create(:user, :activated, :team_admin, team: new_team, organisation: new_team.organisation) }
  let(:deleting_user) { create(:user) }

  describe ".call" do
    subject(:result) { delete_team }

    def delete_team
      described_class.call(team: team, new_team: new_team, user: deleting_user)
    end

    context "with no parameters" do
      let(:team) { nil }
      let(:new_team) { nil }
      let(:deleting_user) { nil }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no team parameter" do
      let(:team) { nil }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no new_team parameter" do
      let(:new_team) { nil }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      let(:deleting_user) { nil }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with required parameters" do
      let!(:team_case) { create(:allegation, creator: team_user) }
      let(:deleting_user) { team_user }

      context "when the team is already deleted" do
        let(:team) { create(:team, :deleted) }

        it "returns a failure" do
          expect(result).to be_failure
        end
      end

      context "when the new team is already deleted" do
        let(:new_team) { create(:team, :deleted) }

        it "returns a failure" do
          expect(result).to be_failure
        end
      end

      it "marks the team as deleted" do
        freeze_time do
          expect { delete_team }.to change(team, :deleted_at).from(nil).to(Time.zone.now)
        end
      end

      it "migrates the users to the new team" do
        expect { delete_team }.to change { team_user.reload.team }.from(team).to(new_team)
      end

      it "retains the users' roles in the new team" do
        expect { delete_team }.not_to change(team_user, :is_team_admin?)
      end

      context "when a user is attributed to historic activity on a case" do
        it "retains the user attribution" do
          activity = team_case.activities.find_by!(type: team_case.case_created_audit_activity_class.to_s)
          expect { delete_team }.not_to change { activity.source.user }
        end
      end

      context "when a user on the team has created a case" do
        it "retains the user as the case creator" do
          expect { delete_team }.not_to change(team_case, :creator_user)
        end

        it "retains the team as the case creator" do
          expect { delete_team }.not_to change(team_case, :creator_team)
        end
      end

      context "when the team is the owner of a case" do
        before do
          ChangeCaseOwner.call!(
            investigation: team_case,
            owner: team,
            user: team_user
          )
        end

        it "transfers ownership of the case to the new team" do
          expect { delete_team }.to change { team_case.reload.owner }.from(team).to(new_team)
        end

        it "adds activity showing the case ownership changed to the new team", :aggregate_failures do
          delete_team
          activity = team_case.activities.find_by!(type: AuditActivity::Investigation::UpdateOwner.to_s)
          expect(activity.owner).to eq(new_team)
          expect(activity.body).to eq("#{team.name} was merged into #{new_team.name} by #{deleting_user.name} (#{deleting_user.team.name}). #{team.name} previously owned this case.")
        end

        it "does not send notification e-mails", :with_test_queue_adapter, :aggregate_failures do
          expect { delete_team }.not_to have_enqueued_mail(NotifyMailer, :investigation_updated)
          expect { delete_team }.not_to have_enqueued_mail(NotifyMailer, :team_deleted_from_case_email)
        end

        context "when the new team was already a collaborator on the case" do
          before do
            AddTeamToCase.call!(
              investigation: team_case,
              user: team_user,
              team: new_team,
              collaboration_class: Collaboration::Access::ReadOnly
            )
          end

          it "removes the previous collaborator access from the new team" do
            expect { delete_team }.to change { team_case.teams_with_read_only_access.count }.from(1).to(0)
          end
        end
      end

      context "when a user in the team is the owner of a case" do
        it "retains the ownership of the case with the same user in the new team" do
          expect { delete_team }.not_to change(team_case, :owner)
        end

        it "updates the owner team to the user's new team" do
          expect { delete_team }.to change { team_case.reload.owner_team }.from(team).to(new_team)
        end

        it "adds activity showing the case ownership changed to the new team", :aggregate_failures do
          delete_team
          activity = team_case.activities.find_by!(type: AuditActivity::Investigation::UpdateOwner.to_s)
          expect(activity.owner).to eq(new_team)
          expect(activity.body).to eq("#{team.name} was merged into #{new_team.name} by #{deleting_user.name} (#{deleting_user.team.name}). #{team.name} previously owned this case.")
        end

        it "does not send notification e-mails", :with_test_queue_adapter, :aggregate_failures do
          expect { delete_team }.not_to have_enqueued_mail(NotifyMailer, :investigation_updated)
          expect { delete_team }.not_to have_enqueued_mail(NotifyMailer, :team_deleted_from_case_email)
        end
      end

      context "when the team is a collaborator on a case owned by the new team" do
        let!(:new_team_case) { create(:allegation, creator: new_team_user, read_only_teams: [team]) }

        it "removes the team from the case" do
          expect { delete_team }.to change { new_team_case.reload.teams_with_read_only_access }.from([team]).to([])
        end

        it "adds activity showing the old team removed from the case", :aggregate_failures do
          delete_team
          activity = new_team_case.activities.find_by!(type: AuditActivity::Investigation::TeamDeleted.to_s)
          expect(activity.team).to eq(team)
          expect(activity.metadata["message"]).to eq("#{team.name} was merged into #{new_team.name} by #{deleting_user.name} (#{deleting_user.team.name}). #{team.name} previously had access to this case.")
        end

        it "does not change the new team's access level on the case" do
          expect { delete_team }.not_to change(new_team_case, :owner_team)
        end

        it "does not send notification e-mails", :with_test_queue_adapter do
          expect { delete_team }.not_to have_enqueued_mail(NotifyMailer, :team_deleted_from_case_email)
        end
      end

      context "when the team is a collaborator on a case owned by another team" do
        let!(:other_team_case) { create(:allegation, read_only_teams: read_only_teams, edit_access_teams: edit_access_teams) }
        let(:read_only_teams) { [team] }
        let(:edit_access_teams) { nil }

        it "adds activity showing the old team removed from the case", :aggregate_failures do
          delete_team
          activity = other_team_case.activities.find_by!(type: AuditActivity::Investigation::TeamDeleted.to_s)
          expect(activity.team).to eq(team)
          expect(activity.metadata["message"]).to eq("#{team.name} was merged into #{new_team.name} by #{deleting_user.name} (#{deleting_user.team.name}). #{team.name} previously had access to this case.")
        end

        it "does not send notification e-mails", :with_test_queue_adapter, :aggregate_failures do
          expect { delete_team }.not_to have_enqueued_mail(NotifyMailer, :team_added_to_case_email)
          expect { delete_team }.not_to have_enqueued_mail(NotifyMailer, :team_deleted_from_case_email)
          expect { delete_team }.not_to have_enqueued_mail(NotifyMailer, :case_permission_changed_for_team)
        end

        context "when the new team is not already a collaborator on the case" do
          it "adds the new team to the case with the same access level as the old team" do
            expect { delete_team }.to change { other_team_case.reload.teams_with_read_only_access }.from([team]).to([new_team])
          end

          it "adds activity showing the new team added to the case", :aggregate_failures do
            delete_team
            activity = other_team_case.activities.find_by!(type: AuditActivity::Investigation::TeamAdded.to_s)
            expect(activity.team).to eq(new_team)
            expect(activity.metadata["message"]).to eq("#{team.name} was merged into #{new_team.name} by #{deleting_user.name} (#{deleting_user.team.name}). #{team.name} previously had access to this case.")
          end
        end

        context "when the new team is already a collaborator on the case" do
          let(:read_only_teams) { [team, new_team] }

          it "does not add activity showing the new team added to the case" do
            expect { delete_team }.not_to change { other_team_case.activities.where(type: AuditActivity::Investigation::TeamAdded.to_s).count }
          end

          context "when the new team has the same level of access to the case as the old team" do
            it "does not change the new team's access level on the case" do
              expect { delete_team }.not_to change { other_team_case.teams_with_read_only_access.where(id: new_team.id).count }
            end
          end

          context "when the new team has read-only access to the case but the old team had edit access" do
            let(:read_only_teams) { [new_team] }
            let(:edit_access_teams) { [team] }

            it "does not change the new team's access level on the case" do
              expect { delete_team }.not_to change { other_team_case.teams_with_read_only_access.where(id: new_team.id).count }
            end
          end

          context "when the new team has edit access to the case but the old team had read-only access" do
            let(:read_only_teams) { [team] }
            let(:edit_access_teams) { [new_team] }

            it "does not change the new team's access level on the case" do
              expect { delete_team }.not_to change { other_team_case.teams_with_read_only_access.where(id: new_team.id).count }
            end
          end
        end
      end
    end
  end
end
