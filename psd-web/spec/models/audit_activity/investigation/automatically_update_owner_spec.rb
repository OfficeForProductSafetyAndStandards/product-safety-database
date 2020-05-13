require "rails_helper"

RSpec.describe AuditActivity::Investigation::AutomaticallyUpdateOwner, :with_stubbed_mailer, :with_stubbed_elasticsearch do
  subject(:audit_activity) { described_class.from(investigation) }

  let(:team) { create(:team) }
  let(:investigation) { create(:enquiry, owner: team, owner_rationale: "Test owner") }

  describe ".from" do
    it "creates an audit activity without information for email notification" do
      expect(audit_activity)
        .to have_attributes(title: "Case owner automatically changed on Enquiry to #{team.display_name}",
                            body: nil,
                            email_update_text: nil,
                            email_subject_text: nil)
    end
  end
end
