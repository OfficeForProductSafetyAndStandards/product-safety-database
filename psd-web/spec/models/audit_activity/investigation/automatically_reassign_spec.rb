require "rails_helper"

RSpec.describe AuditActivity::Investigation::AutomaticallyReassign, :with_stubbed_mailer, :with_stubbed_elasticsearch do
  subject(:audit_activity) { described_class.from(investigation) }

  let(:team) { create(:team) }
  let(:investigation) { create(:enquiry, assignable: team, assignee_rationale: "Test assign") }

  describe ".from" do
    it "creates an audit activity without information for email notification", :aggregate_failures do
      expect(audit_activity.title).to eq("Enquiry automatically reassigned to #{team.display_name}")
      expect(audit_activity.body).to eq(nil)
      expect(audit_activity.email_update_text).to eq(nil)
      expect(audit_activity.email_subject_text).to eq(nil)
    end
  end
end
