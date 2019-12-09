require "rails_helper"

RSpec.describe AuditActivity::Investigation::AddEnquiry, :with_stubbed_elasticsearch do
  let(:enquiry) { create(:enquiry) }

  subject do
    enquiry.activities.find_by!(type: "AuditActivity::Investigation::AddEnquiry")
  end

  describe '#build_title' do
    it "stores the title" do
      expect(subject.title).to eq("Enquiry logged: #{enquiry.decorate.title}")
    end
  end

  describe "#build_body" do
    it "stores the body" do
      expect(subject.body).to eq("**Enquiry details**<br><br>test enquiry")
    end
  end
end
