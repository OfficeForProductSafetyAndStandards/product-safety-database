require "rails_helper"

RSpec.describe AuditActivity::Investigation::UpdateCoronavirusStatus, :with_stubbed_mailer, :with_stubbed_elasticsearch do
  subject(:audit_activity) { described_class.from(investigation) }

  let(:user) { create(:user).decorate }
  let(:investigation) { create(:enquiry) }

  before { User.current = user }

  describe ".from" do
    it "creates an audit activity" do
      expect(audit_activity).to have_attributes(title: "Status updated: not coronavirus related",
                                                body: "The case is not related to the coronavirus outbreak.",
                                                email_update_text: "#{investigation.case_type.capitalize} #{investigation.pretty_id} is not related to the coronavirus outbreak. This status was updated by #{user.display_name}.",
                                                email_subject_text: "Coronavirus status updated on #{investigation.case_type.downcase}")
    end
  end
end
