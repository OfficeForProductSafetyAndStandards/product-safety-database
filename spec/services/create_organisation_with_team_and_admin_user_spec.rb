require "rails_helper"

RSpec.describe CreateOrganisationWithTeamAndAdminUser, :with_stubbed_mailer do
  let(:email) { Faker::Internet.email }
  let(:org_name) { Faker::Team.name }

  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no org_name parameter" do
      let(:result) { described_class.call(admin_email: email) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no admin_email parameter" do
      let(:result) { described_class.call(org_name:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no country" do
      let(:result) { described_class.call(org_name:, admin_email: email) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with required parameters" do
      let(:result) { described_class.call(org_name:, admin_email: email, country: "country:GB") }
      let(:created_org) { Organisation.find_by name: org_name }
      let(:created_team) { Team.find_by name: org_name }
      let(:created_user) { User.find_by email: }
      let(:invitation_email) { delivered_emails.last }

      context "when an exception is raised" do
        let(:exception) { StandardError.new }

        before { allow(SendUserInvitationJob).to receive(:perform_later).and_raise(exception) }

        it "bubbles up the exception" do
          expect { result }.to raise_error(exception)
        end

        it "does not save the organisation" do
          expect(created_org).to be_nil
        end

        it "does not save the team" do
          expect(created_team).to be_nil
        end

        it "does not save the user" do
          expect(created_user).to be_nil
        end
      end

      context "when no exceptions are raised" do
        it "returns success" do
          expect(result).to be_success
        end

        it "creates an Organisation" do
          expect { result }.to change(Organisation, :count).by(1)
        end

        it "creates a Team" do
          expect { result }.to change(Team, :count).by(1)
        end

        it "associates the team with the organisation" do
          result
          expect(created_team.organisation).to eq(created_org)
        end

        it "creates a User" do
          expect { result }.to change(User, :count).by(1)
        end

        it "associates the user with the team" do
          result
          expect(created_user.team).to eq(created_team)
        end

        it "associates the user with the organisation" do
          result
          expect(created_user.organisation).to eq(created_org)
        end

        it "creates an invitation token for the user" do
          result
          expect(created_user.invitation_token.length).to be > 1
        end

        it "adds the team_admin role to the user" do
          result
          expect(created_user).to be_is_team_admin
        end

        it "sends an email to the user", :with_test_queue_adapter do
          expect { result }.to(have_enqueued_job(SendUserInvitationJob).at(:no_wait).on_queue("psd").with do |user_id|
            expect(user_id).to eq created_user.id
          end)
        end
      end
    end
  end
end
