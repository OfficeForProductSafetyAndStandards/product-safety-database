require "rails_helper"

RSpec.describe AuditActivity::Investigation::UpdateAssignee, :with_stubbed_mailer, :with_stubbed_elasticsearch do
  subject(:audit_activity) { described_class.from(investigation) }

  let(:user) { create(:user).decorate }
  let(:investigation) { create(:enquiry, assignable: user, assignee_rationale: "Test assign") }

  around do |ex|
    User.current = user
    ex.run
    User.current = nil
  end

  describe ".from" do
    it "creates an audit activity with information for email notification", :aggregate_failures do
      expect(audit_activity).to have_attributes(title: "Assigned to #{user.display_name}",
                                                body: investigation.assignee_rationale,
                                                email_subject_text: "Enquiry was reassigned")
      expect(audit_activity.email_update_text).to start_with("Enquiry was assigned to #{user.display_name} by #{user.name}")
    end
  end
end
