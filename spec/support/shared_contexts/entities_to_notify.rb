RSpec.shared_examples "a service which notifies teams with access" do
  let(:team_with_edit_access_email)     { Faker::Internet.unique.email }
  let(:team_with_readonly_access_email) { Faker::Internet.unique.email }
  let(:team_with_edit_access)           { create(:team, team_recipient_email: team_with_edit_access_email) }
  let(:team_with_readonly_access)       { create(:team, team_recipient_email: team_with_readonly_access_email) }
  let(:user_with_edit_access)           { create(:user, :activated, team: team_with_readonly_access) }
  let(:user_with_readonly_access)       { create(:user, :activated, team: team_with_readonly_access) }

  before do
    AddTeamToNotification.call!(
      user:,
      notification: investigation,
      team: team_with_edit_access,
      collaboration_class: Collaboration::Access::Edit
    )
    AddTeamToNotification.call!(
      user:,
      notification: investigation,
      team: team_with_readonly_access,
      collaboration_class: Collaboration::Access::ReadOnly
    )
  end

  context "when the user is the owner" do
    context "when the team has team recipient email" do
      let(:expected_edit_notification_args) do
        [
          investigation.pretty_id,
          team_with_edit_access.name,
          team_with_edit_access.email,
          expected_email_body(user, team_with_edit_access),
          expected_email_subject
        ]
      end

      let(:expected_readonly_notification_args) do
        [
          investigation.pretty_id,
          team_with_readonly_access.name,
          team_with_readonly_access.email,
          expected_email_body(user, team_with_readonly_access),
          expected_email_subject
        ]
      end

      it "notifies the teams with a read only or edit access to the case", :aggregate_failures do
        expect { result }
          .to  have_enqueued_mail(NotifyMailer, :notification_updated)
                 .with(*expected_edit_notification_args)
                 .and have_enqueued_mail(NotifyMailer, :notification_updated)
                        .with(*expected_readonly_notification_args)
      end
    end

    context "when the team does not have a team recipient email" do
      let(:team_with_edit_access_email)     { nil }
      let(:team_with_readonly_access_email) { nil }
      let(:expected_edit_notification_args) do
        [
          investigation.pretty_id,
          user_with_edit_access.name,
          user_with_edit_access.email,
          expected_email_body(user, user_with_edit_access),
          expected_email_subject
        ]
      end

      let(:expected_readonly_notification_args) do
        [
          investigation.pretty_id,
          user_with_readonly_access.name,
          user_with_readonly_access.email,
          expected_email_body(user, user_with_readonly_access),
          expected_email_subject
        ]
      end

      it "notifies the teams with a read only or edit access to the case", :aggregate_failures do
        expect { result }
          .to  have_enqueued_mail(NotifyMailer, :notification_updated)
                 .with(*expected_edit_notification_args)
                 .and have_enqueued_mail(NotifyMailer, :notification_updated)
                        .with(*expected_readonly_notification_args)
      end
    end
  end
end
