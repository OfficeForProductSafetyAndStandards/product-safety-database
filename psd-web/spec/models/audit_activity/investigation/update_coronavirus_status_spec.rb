require "rails_helper"

RSpec.describe AuditActivity::Investigation::UpdateCoronavirusStatus, :with_stubbed_mailer, :with_stubbed_elasticsearch do
  subject(:audit_activity) { described_class.from(investigation) }

  let(:user) { create(:user).decorate }
  let(:investigation) { create(:enquiry) }

  before { User.current = user }

  describe ".from" do
    it "creates an audit activity", :aggregate_failures do
      expect(audit_activity).to have_attributes(
        body: "The case is not related to the coronavirus outbreak.",
        email_subject_text: "Coronavirus status updated on #{investigation.case_type.downcase}"
      )
      expect(audit_activity.title(user)).to eq("Status updated: not coronavirus related")
      expect(audit_activity.email_update_text(user)).to eq("#{investigation.case_type.capitalize} #{investigation.pretty_id} is not related to the coronavirus outbreak. This status was updated by #{user.name}.")
    end
  end
end
