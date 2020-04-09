require "rails_helper"

RSpec.describe CreateOrganisation, :with_stubbed_mailer do
  let(:email) { Faker::Internet.safe_email }
  let(:org_name) { Faker::Team.name }

  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call() }

      it "returns a failure" do
        expect(result.failure?).to be true
      end
    end

    context "with no org_name parameter" do
      let(:result) { described_class.call(admin_email: email) }

      it "returns a failure" do
        expect(result.failure?).to be true
      end
    end

    context "with no admin_email parameter" do
      let(:result) { described_class.call(org_name: org_name) }

      it "returns a failure" do
        expect(result.failure?).to be true
      end
    end

    context "with required parameters" do
      let(:result) { described_class.call(org_name: org_name, admin_email: email) }
      let(:created_org) { Organisation.find_by name: org_name }
      let(:created_team) { Team.find_by name: org_name }
      let(:created_user) { User.find_by email: email }
      let(:invitation_email) { delivered_emails.last }

      it "returns success" do
        expect(result.success?).to be true
      end

      it "creates an Organisation" do
        expect { result }.to change { Organisation.count }.by(1)
      end

      it "creates a Team" do
        expect { result }.to change { Team.count }.by(1)
      end

      it "associates the team with the organisation" do
        result
        expect(created_team.organisation).to eq(created_org)
      end

      it "creates a User" do
        expect { result }.to change { User.count }.by(1)
      end

      it "associates the user with the team" do
        result
        expect(created_user.teams.first).to eq(created_team)
      end

      it "associates the user with the organisation" do
        result
        expect(created_user.organisation).to eq(created_org)
      end

      it "creates an invitation token for the user" do
        result
        expect(created_user.invitation_token.length).to be > 1
      end

      it "adds the psd_user role to the user" do
        result
        expect(created_user).to be_is_psd_user
      end

      it "adds the team_admin role to the user" do
        result
        expect(created_user).to be_is_team_admin
      end

      it "sends the invitation email to the user" do
        result
        expect(invitation_email.recipient).to eq(email)
        expect(invitation_email.personalization_path(:invitation_url)).to eq complete_registration_user_path(created_user.id, invitation: created_user.invitation_token)
      end
    end
  end
end
