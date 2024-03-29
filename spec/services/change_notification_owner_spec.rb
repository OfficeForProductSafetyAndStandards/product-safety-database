require "rails_helper"

RSpec.describe ChangeNotificationOwner, :with_test_queue_adapter do
  subject(:result) { described_class.call(notification:, user:, owner: new_owner, rationale:) }

  let(:team) { create(:team) }

  let(:creator) { create(:user, :activated, team:, organisation: team.organisation) }
  let(:old_owner) { creator }
  let(:new_team) { team }
  let(:new_owner) { create(:user, :activated, team: new_team, organisation: team.organisation) }
  let(:user) { create(:user, :activated, team:, organisation: team.organisation) }
  let(:rationale) { "Test rationale" }
  let(:notification) { create(:notification, creator:) }

  context "without search index", :with_stubbed_opensearch do
    before { set_old_owner }

    context "with no parameters" do
      subject(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no notification parameter" do
      subject(:result) { described_class.call(owner: new_owner, user:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      subject(:result) { described_class.call(owner: new_owner, notification:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no owner parameter" do
      subject(:result) { described_class.call(notification:, user:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with required parameters" do
      it "returns success" do
        expect(result).to be_success
      end

      context "when the silent parameter is true", :with_test_queue_adapter do
        subject(:result) do
          described_class.call(
            notification:,
            user:,
            owner: new_owner,
            rationale:,
            silent: true
          )
        end

        it "does not send any emails" do
          expect { result }.not_to have_enqueued_mail(NotifyMailer, :notification_updated)
        end
      end

      context "when the new owner is a read only team on the case" do
        let(:new_owner) { create(:team) }

        before do
          AddTeamToNotification.call!(notification:, user: notification.owner_user, team: new_owner, collaboration_class: Collaboration::Access::ReadOnly)
        end

        specify { expect(result).to be_success }
      end

      context "when the new owner is the same as the old owner" do
        let(:new_owner) { old_owner }

        it "does not create an audit activity" do
          expect { result }.not_to change(Activity, :count)
        end

        it "does not send an email" do
          expect { result }.not_to have_enqueued_mail(NotifyMailer, :notification_updated)
        end
      end

      it "changes the owner" do
        expect { result }.to change(notification, :owner).from(old_owner).to(new_owner)
      end

      it "creates an audit activity for owner changed", :aggregate_failures do
        expect { result }.to change(Activity, :count).by(1)
        activity = notification.reload.activities.first
        expect(activity).to be_a(AuditActivity::Investigation::UpdateOwner)
        expect(activity.added_by_user).to eq(user)
        expect(activity.metadata).to eq(AuditActivity::Investigation::UpdateOwner.build_metadata(new_owner, rationale).deep_stringify_keys)
      end

      it "sends a notification email to the new owner" do
        expect { result }.to have_enqueued_mail(NotifyMailer, :notification_updated).with(
          notification.pretty_id,
          new_owner.name,
          new_owner.email,
          expected_email_body,
          expected_email_subject
        )
      end

      it "sends a notification email to the old owner" do
        expect { result }.to have_enqueued_mail(NotifyMailer, :notification_updated).with(
          notification.pretty_id,
          old_owner.name,
          old_owner.email,
          expected_email_body,
          expected_email_subject
        )
      end

      context "when no rationale is supplied", :with_stubbed_opensearch do
        let(:rationale) { nil }

        it "does not add a message to the notification email" do
          expect { result }.to have_enqueued_mail(NotifyMailer, :notification_updated).with(
            notification.pretty_id,
            old_owner.name,
            old_owner.email,
            "Owner changed on notification to #{new_owner.name} by #{user.name}.",
            expected_email_subject
          )
        end
      end

      context "when the user is the same as the old owner" do
        let(:user) { old_owner }

        it "does not send a notification email to the old owner" do
          expect { result }.not_to have_enqueued_mail(NotifyMailer, :notification_updated).with(
            notification.pretty_id,
            old_owner.name,
            old_owner.email,
            expected_email_body,
            expected_email_subject
          )
        end
      end

      context "when the new owner is a Team" do
        let(:new_owner) { team }

        context "when the team has a an email address" do
          let(:team) { create(:team, team_recipient_email: Faker::Internet.email) }

          it "sends a notification email to the team" do
            expect { result }.to have_enqueued_mail(NotifyMailer, :notification_updated).with(
              notification.pretty_id,
              team.name,
              team.team_recipient_email,
              expected_email_body,
              expected_email_subject
            )
          end
        end

        context "when the team does not have an email address" do
          let(:team) { create(:team, team_recipient_email: nil) }

          # Create an inactive user to test email is not delivered to them
          before { create(:user, team:, organisation: team.organisation) }

          it "sends an email to each of the team's active users" do
            expect { result }.to have_enqueued_mail(NotifyMailer, :notification_updated).twice
          end
        end

        context "when the new owner is the same as the creator" do
          let(:new_owner) { creator.team }

          before { result }

          it "creates a new owner collaboration and retains the creator", :aggregate_failures do
            expect(notification.creator_team_collaboration.collaborator).to eq(creator.team)
            expect(notification.owner_team_collaboration.collaborator).to eq(new_owner)
            expect(notification.owner_user_collaboration).to be_nil
          end
        end
      end

      describe "adding old owner as collaborator" do
        shared_examples "collaborator created" do
          it "creates collaboration with edit access" do
            expect { result }.to change(Collaboration::Access::Edit, :count).by(1)
          end

          it "creates proper collaboration" do
            result
            expect(notification.teams_with_edit_access).to contain_exactly(creator_team, notification.owner_team)
          end
        end

        shared_examples "collaborator not created" do
          subject(:result) { described_class.call(notification:, user:, owner: new_owner, rationale:) }

          it "creates no collaboration" do
            expect { result }.not_to(change(Collaboration::Access::Edit, :count))
          end
        end

        let(:other_team)   { create(:team) }
        let(:creator_team) { team }

        context "when old owner is team, new owner is team" do
          let(:old_owner) { team }
          let(:new_owner) { other_team }

          include_examples "collaborator created"
        end

        context "when the old owner is a user and the new owner is a team" do
          let(:old_owner) { creator }
          let(:new_owner) { other_team }

          it "correctly swaps the owner" do
            expect { result }.to change(notification, :owner_user)
                                    .from(old_owner)
                                    .to(nil)
                                    .and change(notification, :owner_team)
                                          .from(old_owner.team).to(new_owner)
          end
        end

        context "when old owner is user, new owner is user" do
          let(:old_owner) { creator }
          let(:new_owner) { create(:user, :activated, team: other_team, organisation: other_team.organisation) }

          include_examples "collaborator created"
        end

        context "when old owner is team, new owner is user" do
          let(:old_owner) { team }
          let(:new_owner) { create(:user, :activated, team: other_team, organisation: other_team.organisation) }

          it "correctly swaps the owner" do
            expect { result }.to change(notification, :owner_user)
                                    .from(nil)
                                    .to(new_owner)
                                    .and change(notification, :owner_team)
                                          .from(old_owner).to(new_owner.team)
          end
        end

        context "when old owner is team, new owner is user from the same team" do
          let(:old_owner) { team }
          let(:new_owner) { create(:user, :activated, team:, organisation: team.organisation) }

          it "correctly swaps the owner", :aggregate_failures do
            expect { result }.to change(notification, :owner_user).from(nil).to(new_owner)
            expect(notification.owner_team).to eq(old_owner)
          end
        end

        context "when old owner is user, new owner is user from the same team" do
          let(:new_owner) { create(:user, :activated, team:, organisation: team.organisation) }

          include_examples "collaborator not created"
        end

        context "when the old owner is a user and the new owner is the old owner team" do
          let(:new_owner) { team }

          it "correctly swaps the owner", :aggregate_failures do
            expect { result }.to change(notification, :owner_user).from(old_owner).to(nil)
            expect(notification.owner_team).to eq(team)
          end
        end
      end

      context "when the new owner was previously a collaborator" do
        let(:new_owner) { create(:team) }
        let(:old_collaborator) do
          notification.edit_access_collaborations.create!(
            collaborator: new_owner, include_message: false,
            added_by_user: user
          )
        end

        it "changes the edit collaborator to the owner" do
          expect { result }.to change(notification.reload, :owner_team).from(old_owner.team).to(new_owner)
        end
      end
    end
  end
end

def set_old_owner
  described_class.call!(notification:, owner: old_owner, user: creator)
end

def expected_email_subject
  "Owner changed for notification"
end

def expected_email_body
  "Owner changed on notification to #{new_owner.name} by #{user.name}.\n\nMessage from #{user.name}: ^ Test rationale"
end
