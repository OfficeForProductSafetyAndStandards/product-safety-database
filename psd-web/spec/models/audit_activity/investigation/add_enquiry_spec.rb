require "rails_helper"

RSpec.describe AuditActivity::Investigation::AddEnquiry, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject do
    enquiry.activities.find_by!(type: described_class.name)
  end

  let(:enquiry) { create(:enquiry) }


  describe "#build_title" do
    it "stores the title" do
      expect(subject.title).to eq("Enquiry logged: #{enquiry.decorate.title}")
    end
  end

  describe "#build_body" do
    it "stores the body" do
      expect(subject.body).to eq("**Enquiry details**<br><br>#{enquiry.description}<br><br>Assigned to #{enquiry.assignee.display_name}.")
    end
  end
end
