RSpec.shared_examples "sends notification to case owner" do
  context "when the user is the case owner" do
    before { ChangeCaseOwner.call!(investigation: investigation, owner: user, user: user) }

    it "does not send an email" do
      expect { result }.not_to have_enqueued_mail(NotifyMailer, :investigation_updated)
    end
  end

  context "when the user's team is the case owner" do
    before { ChangeCaseOwner.call!(investigation: investigation, owner: user.team, user: user) }

    it "does not send an email" do
      expect { result }.not_to have_enqueued_mail(NotifyMailer, :investigation_updated)
    end
  end

  context "when the case owner is a user on the same team" do
    let(:user_same_team) { create(:user, :activated, team: user.team, organisation: user.organisation) }

    before { ChangeCaseOwner.call!(investigation: investigation, owner: user_same_team, user: user) }

    it "sends an email to the user" do
      expect { result }.to have_enqueued_mail(NotifyMailer, :investigation_updated).with(a_hash_including(args: [
        investigation.pretty_id,
        user_same_team.name,
        user_same_team.email,
        expected_email_body(user.name),
        expected_email_subject
      ]))
    end
  end

  context "when the user is on a different team to the case owner" do
    let(:user_other_team) { create(:user, :activated, team: other_team) }
    let(:other_team) { create(:team) }

    context "when the owner is a user" do
      before { ChangeCaseOwner.call!(investigation: investigation, owner: user_other_team, user: user) }

      it "sends an email to the user" do
        expect { result }.to have_enqueued_mail(NotifyMailer, :investigation_updated).with(a_hash_including(args: [
          investigation.pretty_id,
          user_other_team.name,
          user_other_team.email,
          expected_email_body("#{user.name} (#{user.team.name})"),
          expected_email_subject
        ]))
      end
    end

    context "when the owner is a team" do
      before { ChangeCaseOwner.call!(investigation: investigation, owner: other_team, user: user) }

      it "sends an email to the team email" do
        expect { result }.to have_enqueued_mail(NotifyMailer, :investigation_updated).with(a_hash_including(args: [
          investigation.pretty_id,
          other_team.name,
          other_team.email,
          expected_email_body("#{user.name} (#{user.team.name})"),
          expected_email_subject
        ]))
      end

      context "when the owner team does not have an email address" do
        let(:other_team) { create(:team, team_recipient_email: nil) }

        # Create an inactive user to test email is not delivered to them
        before { create(:user, team: other_team, organisation: other_team.organisation) }

        it "sends an email to each of the team's active users" do
          expect { result }.to have_enqueued_mail(NotifyMailer, :investigation_updated).with(a_hash_including(args: [
            investigation.pretty_id,
            user_other_team.name,
            user_other_team.email,
            expected_email_body("#{user.name} (#{user.team.name})"),
            expected_email_subject
          ]))
        end
      end
    end
  end
end
