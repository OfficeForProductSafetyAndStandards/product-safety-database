require "rails_helper"

RSpec.describe AuditActivity::Investigation::UpdateOwner, :with_stubbed_mailer, :with_stubbed_elasticsearch do
  subject(:audit_activity) { described_class.from(investigation) }

  let(:user) { create(:user).decorate }
  let(:investigation) { create(:enquiry, owner: user, owner_rationale: "Test owner") }

  before { User.current = user }

  describe ".from" do
    it "creates an audit activity with information for email notification", :aggregate_failures do
      expect(audit_activity).to have_attributes(
        title: "Case owner changed to #{user.display_name}",
        body: investigation.owner_rationale,
        email_subject_text: "Case owner changed for enquiry"
      )
      expect(audit_activity.email_update_text(user)).to start_with("Case owner changed on enquiry to #{user.name} by #{user.name}")
    end
  end
end
