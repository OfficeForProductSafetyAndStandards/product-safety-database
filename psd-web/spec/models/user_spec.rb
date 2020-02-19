require "rails_helper"

RSpec.describe User do
  describe ".activated" do
    it "returns only users with activated accounts" do
      create(:user, :inactive)
      activated_user = create(:user, :activated)

      expect(User.activated.to_a).to eq [activated_user]
    end
  end

  describe ".create_and_send_invite!" do
    context "with valid email and team" do
      let(:email) { "testuser@southampton.gov.uk" }
      let(:team) { create(:team) }
      let(:inviting_user) { create(:user) }
      let(:created_user) { User.find_by(email: email) }

      before do
        allow(SendUserInvitationJob).to receive(:perform_later)
        described_class.create_and_send_invite!(email, team, inviting_user)
      end

      it "creates an user with the given email address" do
        expect(created_user).not_to be_nil
      end

      it "adds a invitation token to the created user" do
        expect(created_user.invitation_token).not_to be_nil
      end

      it "associates the created user with the given team's organisation" do
        expect(created_user.organisation).to eq team.organisation
      end

      it "associates the created user with the given team" do
        expect(created_user.teams).to eq [team]
      end

      it "sends an invitation to the user" do
        expect(SendUserInvitationJob).to have_received(:perform_later).with(anything, inviting_user.id)
      end
    end

    it "raises an error when missing information" do
      email = nil
      team = build_stubbed(:team, organisation: nil)
      inviting_user = build_stubbed(:user)

      expect(SendUserInvitationJob).not_to receive(:perform_later)
      expect { described_class.create_and_send_invite!(email, team, inviting_user) }
        .to raise_exception(ActiveRecord::RecordInvalid)
    end
  end

  describe ".resend_invite" do
    let(:inviting_user) { create(:user_with_teams) }

    it "resends an invitation to the user when both users belong to same team" do
      invited_user = create(:user, teams: inviting_user.teams, organisation: inviting_user.organisation)

      expect(SendUserInvitationJob).to receive(:perform_later).with(anything, inviting_user.id)

      described_class.resend_invite(invited_user.email, inviting_user)
    end

    it "raises an exception when the given email does not match any user" do
      expect(SendUserInvitationJob).not_to receive(:perform_later)
      expect { described_class.resend_invite("inexistent@southampton.gov.uk", inviting_user) }
        .to raise_exception(ActiveRecord::RecordNotFound)
    end

    it "raises an exception when inviting and invited users belong to different teams" do
      invited_user = create(:user_with_teams)

      expect(SendUserInvitationJob).not_to receive(:perform_later)
      expect { described_class.resend_invite(invited_user.email, inviting_user) }
        .to raise_exception(ActiveRecord::RecordNotFound)
    end
  end

  describe ".get_team_members" do
    let(:team) { create(:team) }
    let(:user) { create(:user, :activated, teams: [team]) }
    let(:investigation) { create(:allegation) }
    let(:team_members) { described_class.get_team_members(user: user) }

    let!(:another_active_user) { create(:user, :activated, organisation: user.organisation, teams: [team]) }
    let!(:another_inactive_user) { create(:user, :inactive, organisation: user.organisation, teams: [team]) }
    let!(:another_user_with_another_team) { create(:user, :activated, teams: [create(:team)]) }

    it "returns other users on the same team" do
      expect(team_members).to include(another_active_user)
    end

    it "does not return other users on the same team who are not activated" do
      expect(team_members).not_to include(another_inactive_user)
    end

    it "does not return other users on other teams" do
      expect(team_members).not_to include(another_user_with_another_team)
    end
  end

  describe ".get_assignees" do
    let!(:active_user) { create(:user, :activated) }
    let!(:inactive_user) { create(:user, :inactive) }

    it "returns other users" do
      expect(described_class.get_assignees).to include(active_user)
    end

    it "does not return other users who are not activated" do
      expect(described_class.get_assignees).not_to include(inactive_user)
    end

    it "includes associations needed for display_name" do
      assignees = described_class.get_assignees.to_a # to_a forces the query execution and load immediately
      expect(-> {
        assignees.map(&:display_name)
      }).to not_talk_to_db
    end

    context "when a user to except is supplied" do
      it "does not return the excepted user" do
        expect(described_class.get_assignees(except: active_user)).to be_empty
      end
    end
  end

  describe "#load_roles_from_keycloak", :with_stubbed_keycloak_config do
    let(:user) { create(:user, :psd_user) }
    let(:roles) { %i[test_role another_test_role] }

    before do
      allow(KeycloakClient.instance).to receive(:get_user_roles).with(user.id).and_return(roles)
      user.load_roles_from_keycloak
    end

    it "populates the user roles" do
      expect(user.user_roles.where(name: roles).count).to eq(2)
    end

    it "deletes roles no longer assigned to the user" do
      expect(user.user_roles.where(name: :psd_user)).to be_empty
    end

    context "when the user already has the same roles" do
      let(:roles) { %i[test_role test_role another_test_role] }

      it "does not duplicate roles" do
        expect(user.user_roles.count).to eq(2)
      end
    end
  end

  describe "#display_name" do
    let(:organisation_name) { "test org" }
    let(:other_organisation_name) { "other org" }
    let(:organisation) { create(:organisation, name: organisation_name) }
    let(:other_organisation) { create(:organisation, name: other_organisation_name) }

    let(:team_name) { "test team" }
    let(:other_team_name) { "other team" }
    let(:other_org_team_name) { "other org team" }
    let(:team) { create(:team, name: team_name, organisation: organisation) }
    let(:other_team) { create(:team, name: other_team_name, organisation: organisation) }
    let(:other_organisation_team) { create(:team, name: other_org_team_name, organisation: other_organisation) }

    let(:user_name) { "test user" }
    let(:other_user_name) { "other user" }
    let(:user_organisation) { organisation }
    let(:user_teams) { [] }
    let(:user) { create(:user, name: user_name, organisation: user_organisation, teams: user_teams) }
    let(:other_user) { create(:user, name: other_user_name, organisation: organisation) }

    let(:ignore_visibility_restrictions) { false }

    let(:result) { user.display_name(other_user: other_user, ignore_visibility_restrictions: ignore_visibility_restrictions) }

    context "with other_user" do
      context "when the user is a member of the same organisation" do
        context "when the user has no teams" do
          it "returns their name and organisation name" do
            expect(result).to eq("#{user_name} (#{organisation_name})")
          end
        end

        context "when the user has teams" do
          let(:user_teams) { [team, other_team] }

          it "returns their name and team names" do
            expect(result).to eq("#{user_name} (#{team_name}, #{other_team_name})")
          end
        end
      end

      context "when the user is a member of a different organisation" do
        let(:user_organisation) { other_organisation }

        context "when the user has no teams" do
          it "returns their name and organisation name" do
            expect(result).to eq("#{user_name} (#{other_organisation_name})")
          end
        end

        context "when the user has teams" do
          let(:user_teams) { [other_organisation_team] }

          context "with ignore_visibility_restrictions: false" do
            it "returns their name and organisation name" do
              expect(result).to eq("#{user_name} (#{other_organisation_name})")
            end
          end

          context "with ignore_visibility_restrictions: true" do
            let(:ignore_visibility_restrictions) { true }

            it "returns their name and team names" do
              expect(result).to eq("#{user_name} (#{other_org_team_name})")
            end
          end
        end
      end
    end

    context "with other_user: nil" do
      let(:other_user) { nil }

      it "returns their name and organisation name" do
        expect(result).to eq("#{user_name} (#{organisation_name})")
      end
    end
  end

  describe "#invitation_expired?" do
    it "returns false when the user has not been invited" do
      user = build_stubbed(:user, invited_at: nil)
      expect(user.invitation_expired?).to be_falsey
    end

    it "returns false when user was invited less than 14 days ago" do
      user = build_stubbed(:user, invited_at: 13.days.ago)
      expect(user.invitation_expired?).to be_falsey
    end

    it "returns true when user was invited exactly 14 days ago" do
      user = build_stubbed(:user, invited_at: 14.days.ago)
      expect(user.invitation_expired?).to be true
    end

    it "returns true when user was invited more than 14 days ago" do
      user = build_stubbed(:user, invited_at: 15.days.ago)
      expect(user.invitation_expired?).to be true
    end
  end
end
