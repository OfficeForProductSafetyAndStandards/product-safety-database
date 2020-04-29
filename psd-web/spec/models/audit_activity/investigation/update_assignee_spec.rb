require "rails_helper"

RSpec.describe AuditActivity::Investigation::UpdateAssignee, :with_stubbed_mailer, :with_stubbed_elasticsearch do
  subject(:audit_activity) { described_class.from(investigation) }

  let(:user) { create(:user) }
  let(:investigation) { create(:enquiry, assignable: user, assignee_rationale: "Test assign") }

  around do |ex|
    User.current = user
    ex.run
    User.current = nil
  end

  describe ".from" do
    it "creates an audit activity with information for email notification", :aggregate_failures do
      expect(audit_activity.title).to eq("Assigned to #{user.decorate.display_name}")
      expect(audit_activity.body).to eq(investigation.assignee_rationale)
      expect(audit_activity.email_update_text).to start_with("Enquiry was assigned to #{user.decorate.display_name} by #{user.name}")
      expect(audit_activity.email_subject_text).to eq("Enquiry was reassigned")
    end
  end
end
