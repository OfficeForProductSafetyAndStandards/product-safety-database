require "rails_helper"

RSpec.describe AuditActivity::Investigation::DeleteAssignee, :with_stubbed_mailer, :with_stubbed_elasticsearch do
  subject(:audit_activity) { described_class.from(investigation) }

  let(:user) { create(:user) }
  let(:investigation) { create(:enquiry, assignee: user) }

  describe ".from" do
    it "creates an audit activity" do
      expect(audit_activity.title).to eq(
        "User #{user.display_name} deleted"
      )
    end
  end
end
