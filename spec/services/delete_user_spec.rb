RSpec.describe DeleteUser, :with_stubbed_mailer, :with_stubbed_opensearch do
  describe ".call" do
    context "with no parameters" do
      subject(:delete_call) { described_class.call }

      it "returns a failure" do
        expect(delete_call).to be_failure
      end

      it "provides an error message" do
        expect(delete_call.error).to eq "No user supplied"
      end
    end

    context "when given an user that is already deleted" do
      subject(:delete_call) { described_class.call(user:) }

      let(:user) { create(:user, :deleted) }

      it "returns a failure" do
        expect(delete_call).to be_failure
      end

      it "provides an error message" do
        expect(delete_call.error).to eq "User already deleted"
      end
    end

    context "when given an user that is not already deleted" do
      subject(:delete_call) { described_class.call(user:) }

      let(:user)        { create(:user) }
      let!(:allegation) { create(:allegation, creator: user) }
      let!(:enquiry)    { create(:enquiry, creator: user) }
      let!(:project)    { create(:project, creator: user) }

      it "succeeds" do
        expect(delete_call).to be_a_success
      end

      # rubocop:disable RSpec/ExampleLength
      it "sets the user deleted timestamp" do
        freeze_time do
          expect {
            delete_call
            user.reload
          }.to change(user, :deleted_at).from(nil).to(Time.zone.now)
        end
      end

      it "changes user cases ownership to their team" do
        expect {
          delete_call
          allegation.reload
          enquiry.reload
          project.reload
        }.to change(allegation, :owner).from(user).to(user.team)
         .and change(enquiry, :owner).from(user).to(user.team)
         .and change(project, :owner).from(user).to(user.team)
      end

      it "registers the owner automatic update in the investigations activity log", :aggregate_failures do
        update_owner_activities = Activity.where(type: "AuditActivity::Investigation::AutomaticallyUpdateOwner")

        expect { delete_call }.to change(update_owner_activities, :count).by(3)

        update_owner_activities.last(3).each do |activity|
          expect(activity.title(user)).to start_with "Notification owner automatically changed on"
          expect(activity.title(user)).to end_with "to #{user.team.name}"
        end
      end
      # rubocop:enable RSpec/ExampleLength

      it "does not send notifications to the user or the team" do
        expect { delete_call }.not_to change(delivered_emails, :count)
      end
    end
  end
end
