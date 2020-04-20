require "rails_helper"

RSpec.describe DeleteUser, :with_stubbed_mailer, :with_stubbed_elasticsearch do
  describe ".call" do
    context "with no parameters" do
      subject(:delete_call) { described_class.call }

      it "returns a failure" do
        expect(delete_call).to be_failure
      end

      it "provides an error message" do
        expect(delete_call.error).to eq "Missing parameters: Need either user_id or user_email"
      end
    end

    context "when given an user id" do
      context "when the given user id does not match any user" do
        subject(:delete_call) { described_class.call(user_id: SecureRandom.uuid) }

        it "returns a failure" do
          expect(delete_call).to be_failure
        end

        it "provides an error message" do
          expect(delete_call.error).to eq "User not found"
        end
      end

      context "when the given user id belongs to an user" do
        subject(:delete_call) { described_class.call(user_id: user.id) }

        let(:user) { create(:user_with_teams, teams_count: 2) }
        let(:user_first_team) { user.teams.first }
        let!(:allegation) { create(:allegation, assignee: user) }
        let!(:enquiry) { create(:enquiry, assignee: user) }
        let!(:project) { create(:project, assignee: user) }

        it "succeeds" do
          expect(delete_call).to be_a_success
        end

        it "sets the user as deleted" do
          expect {
            delete_call
            user.reload
          }.to change(user, :deleted).from(false).to(true)
        end

        # rubocop:disable RSpec/ExampleLength
        it "reassigns user cases to their first team" do
          expect {
            delete_call
            allegation.reload
            enquiry.reload
            project.reload
          }.to change(allegation, :assignee).from(user).to(user_first_team)
           .and change(enquiry, :assignee).from(user).to(user_first_team)
           .and change(project, :assignee).from(user).to(user_first_team)
        end
        # rubocop:enable RSpec/ExampleLength

        it "does not send notifications to the user or the team" do
          expect { delete_call }.not_to change(delivered_emails, :count)
        end
      end
    end

    context "when given an user email" do
      context "when the given user email does not match any user" do
        subject(:delete_call) { described_class.call(user_email: Faker::Internet.safe_email) }

        it "returns a failure" do
          expect(delete_call).to be_failure
        end

        it "provides an error message" do
          expect(delete_call.error).to eq "User not found"
        end
      end

      context "when the given email belongs to an user" do
        subject(:delete_call) { described_class.call(user_email: user.email) }

        let(:user) { create(:user) }


        it "succeeds" do
          expect(delete_call).to be_a_success
        end

        it "sets the user as deleted" do
          expect {
            delete_call
            user.reload
          }.to change(user, :deleted).from(false).to(true)
        end
      end
    end


    context "when given both user id and user email corresponding to different users" do
      subject(:delete_call) { described_class.call(user_id: user_matching_id.id, user_email: user_matching_email.email) }

      let(:user_matching_id) { create(:user) }
      let(:user_matching_email) { create(:user) }


      it "succeeds" do
        expect(delete_call).to be_a_success
      end

      it "sets the user matching the given id as deleted" do
        expect {
          delete_call
          user_matching_id.reload
        }.to change(user_matching_id, :deleted).from(false).to(true)
      end

      it "does not set the user matching the given email as deleted" do
        expect {
          delete_call
          user_matching_email.reload
        }.not_to change(user_matching_email, :deleted).from(false)
      end
    end
  end
end
