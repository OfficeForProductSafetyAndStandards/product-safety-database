require "rails_helper"

RSpec.describe User do
  include ActiveSupport::Testing::TimeHelpers

  describe "attributes" do
    let(:user) { described_class.new }

    describe "invitation_token" do
      before { allow(SecureRandom).to receive(:hex).with(15).and_return(expected_token) }

      let(:expected_token) { "abcd1234" }

      it "is generated on instantiation" do
        expect(user.invitation_token).to eq(expected_token)
      end
    end

    describe "invited_at" do
      it "is generated on instantiation" do
        expect(user.invited_at).to be_within(1.second).of(Time.current)
      end
    end
  end

  describe "validations" do
    before { user.validate(:registration_completion) }

    context "with registration_completion context" do
      context "with blank mobile number" do
        let(:user) { build(:user, mobile_number: "") }

        it "is not valid" do
          expect(user).not_to be_valid(:registration_completion)
        end

        it "populates an error message" do
          expect(user.errors.messages[:mobile_number]).to eq ["Enter your mobile number"]
        end
      end

      context "with invalid mobile number format" do
        let(:user) { build(:user, mobile_number: "01111111111") }

        it "is not valid" do
          expect(user).not_to be_valid(:registration_completion)
        end

        it "populates an error message" do
          expect(user.errors.messages[:mobile_number]).to eq [
            "Enter your mobile number in the correct format, like 07700 900 982"
          ]
        end
      end

      context "with blank name" do
        let(:user) { build(:user, name: "") }

        it "is not valid" do
          expect(user).not_to be_valid(:registration_completion)
        end

        it "populates an error message" do
          expect(user.errors.messages[:name]).to eq ["Enter your full name"]
        end
      end

      context "with blank password" do
        let(:user) { build(:user, password: "") }

        it "is not valid" do
          expect(user).not_to be_valid(:registration_completion)
        end

        it "populates an error message" do
          expect(user.errors.messages[:password]).to eq ["Enter a password"]
        end
      end

      context "with a password that is too short" do
        let(:user) { build(:user, password: "123456") }

        it "is not valid" do
          expect(user).not_to be_valid(:registration_completion)
        end

        it "populates an error message" do
          expect(user.errors.messages[:password])
            .to eq ["Password is too short"]
        end
      end

      context "with a commonly-used password" do
        let(:user) { build(:user, password: "password") }

        it "is not valid" do
          expect(user).not_to be_valid(:registration_completion)
        end

        it "populates an error message" do
          expect(user.errors.messages[:password])
            .to eq ["Choose a less frequently used password"]
        end
      end
    end
  end

  describe ".activated" do
    it "returns only users with activated accounts" do
      create(:user, :inactive)
      activated_user = create(:user, :activated)

      expect(described_class.activated.to_a).to eq [activated_user]
    end
  end

  describe ".create_and_send_invite!" do
    context "with valid email and team" do
      let(:email) { "testuser@southampton.gov.uk" }
      let(:team) { create(:team) }
      let(:inviting_user) { create(:user) }
      let(:created_user) { described_class.find_by(email: email) }
      let(:created_user_roles) { created_user.user_roles.pluck(:name) }

      before do
        allow(SendUserInvitationJob).to receive(:perform_later)
        described_class.create_and_send_invite!(email, team, inviting_user)
      end

      it "creates an user with the given email address" do
        expect(created_user).not_to be_nil
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

      it "adds the psd_user role" do
        expect(created_user_roles).to eq %w[psd_user]
      end

      context "when the inviting user is an OPSS user" do
        let(:inviting_user) { create(:user, :opss_user) }

        it "invited user gets the opss role" do
          expect(created_user_roles).to include("opss_user")
        end
      end

      context "when the inviting user is a team admin" do
        let(:inviting_user) { create(:user, :team_admin) }

        it "invited user does not get the team admin role" do
          expect(created_user_roles).not_to include("team_admin")
        end
      end

      context "when the inviting user is a PSD admin" do
        let(:inviting_user) { create(:user, :psd_admin) }

        it "invited user does not get the psd admin role" do
          expect(created_user_roles).not_to include("psd_admin")
        end
      end
    end

    context "when missing information" do
      let(:email) { nil }
      let(:team) { build_stubbed(:team, organisation: nil) }
      let(:inviting_user) { build_stubbed(:user) }

      before { allow(SendUserInvitationJob).to receive(:perform_later) }

      it "raises an exception and does not send the invitation", :aggregate_failures do
        expect { described_class.create_and_send_invite!(email, team, inviting_user) }
          .to raise_exception(ActiveRecord::RecordInvalid)
        expect(SendUserInvitationJob).not_to have_received(:perform_later)
      end
    end
  end

  describe ".resend_invite" do
    let(:inviting_user) { create(:user_with_teams) }

    before { allow(SendUserInvitationJob).to receive(:perform_later) }

    context "when both users belong to same team" do
      let!(:invitation_token) { SecureRandom.hex }
      let(:invited_user) { create(:user, teams: inviting_user.teams, organisation: inviting_user.organisation, invitation_token: invitation_token) }

      it "resends an invitation to the user", :aggregate_failures do
        expect {
          described_class.resend_invite(invited_user.email, inviting_user)
        }.to(change { invited_user.reload.invited_at })
        expect(SendUserInvitationJob).to have_received(:perform_later).with(anything, inviting_user.id)
      end

      context "when the invitee has already been sent an invite but has not yet accepted it" do
        it "does not change the existing invitation token" do
          expect { described_class.resend_invite(invited_user.email, inviting_user) }
            .not_to(change { invited_user.reload.invitation_token })
        end
      end

      context "when the invitee does not have an invitation token" do
        before { invited_user.update!(invitation_token: nil) }

        it "re-regerates the token" do
          allow(SecureRandom).to receive(:hex).with(15).and_return("new_token")
          expect {
            described_class.resend_invite(invited_user.email, inviting_user)
          }.to change { invited_user.reload.invitation_token }.from(nil).to("new_token")
        end
      end
    end

    context "when the given email does not match any user" do
      let(:email) { "inexistent@southampton.gov.uk" }

      it "raises an exception and does not send the invitation", :aggregate_failures do
        expect { described_class.resend_invite(email, inviting_user) }
          .to raise_exception(ActiveRecord::RecordNotFound)
        expect(SendUserInvitationJob).not_to have_received(:perform_later)
      end
    end

    context "when inviting and invited users belong to different teams" do
      let(:invited_user) { create(:user_with_teams) }

      it "raises an exception and does not send the invitation", :aggregate_failures do
        expect { described_class.resend_invite(invited_user.email, inviting_user) }
          .to raise_exception(ActiveRecord::RecordNotFound)
        expect(SendUserInvitationJob).not_to have_received(:perform_later)
      end
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

  describe ".get_owners" do
    let!(:active_user) { create(:user, :activated) }
    let!(:inactive_user) { create(:user, :inactive) }

    it "returns other users" do
      expect(described_class.get_owners).to include(active_user)
    end

    it "does not return other users who are not activated" do
      expect(described_class.get_owners).not_to include(inactive_user)
    end

    it "includes associations needed for display_name" do
      assignees = described_class.get_owners.to_a # to_a forces the query execution and load immediately
      expect(-> {
        assignees.map(&:display_name)
      }).to not_talk_to_db
    end

    context "when a user to except is supplied" do
      it "does not return the excepted user" do
        expect(described_class.get_owners(except: active_user)).to be_empty
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

    context "with other_user: nil" do
      let(:other_user) { nil }

      it "returns their name and organisation name" do
        expect(result).to eq("#{user_name} (#{organisation_name})")
      end
    end
  end


  describe "#send_reset_password_instructions" do
    subject(:user) { create(:user) }

    let!(:reset_token) { stubbed_devise_generated_token }

    it "enqueues a job posting email to notify with the none encrypted token", :with_test_queue_adapter do
      message_delivery = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
      allow(NotifyMailer).to receive(:reset_password_instructions).with(user, reset_token.first).and_return(message_delivery)

      user.send_reset_password_instructions

      expect(message_delivery).to have_received(:deliver_later)
    end
  end

  describe "#invitation_expired?" do
    it "returns false when user was invited less than 14 days ago" do
      user = build_stubbed(:user, invited_at: 13.days.ago)
      expect(user.invitation_expired?).to be false
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

  describe "#has_completed_registration?" do
    context "when the password, name and mobile number are missing" do
      let(:user) { build_stubbed(:user, password: nil, name: nil, mobile_number: nil) }

      it "is false" do
        expect(user.has_completed_registration?).to be false
      end
    end

    context "when the password, name and mobile number have all been set" do
      let(:user) { build_stubbed(:user) }

      it "is true" do
        expect(user.has_completed_registration?).to be true
      end
    end
  end
end
