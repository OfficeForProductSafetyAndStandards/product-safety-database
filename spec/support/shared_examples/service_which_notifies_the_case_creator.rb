RSpec.shared_examples "a service which notifies the case creator", :with_test_queue_adapter do |even_when_the_case_is_closed: false|
  let!(:investigation) { create(:enquiry, is_closed: false, creator: creator_user) }

  context "when the user is the case creator" do
    let(:creator_user) { user }

    it "does not send an email" do
      expect { result }.not_to have_enqueued_mail(NotifyMailer, :investigation_updated)
    end
  end

  context "when the user is not the case creator" do
    let(:creator_user) { create(:user, :activated, team: user.team, organisation: user.organisation) }

    it "sends an email to the user" do
      expect { result }.to have_enqueued_mail(NotifyMailer, :investigation_updated).with(
        investigation.pretty_id,
        creator_user.name,
        creator_user.email,
        expected_email_body(user.name),
        expected_email_subject
      )
    end

    unless even_when_the_case_is_closed
      context "when the case is closed" do
        before { ChangeCaseStatus.call!(investigation:, user:, new_status: "closed") }

        it "does not send an email" do
          expect { result }.not_to have_enqueued_mail(NotifyMailer, :investigation_updated)
        end
      end
    end
  end
end
