require "rails_helper"

RSpec.describe AuditActivity::Investigation::AddEnquiry, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:activity) do
    enquiry.activities.find_by!(type: described_class.name)
  end

  let(:enquiry) { create(:enquiry) }

  describe "#build_title" do
    it "stores the title" do
      expect(activity.title).to eq("Enquiry logged: #{enquiry.decorate.title}")
    end
  end

  describe "#build_body" do
    it "stores the body" do
      expect(activity.body).to eq("**Enquiry details**<br><br>#{enquiry.description}<br><br>Case owner: #{enquiry.assignable.decorate.display_name}")
    end

    context "when case is coronavirus related" do
      let(:enquiry) { create(:enquiry, coronavirus_related: true) }

      it "adds text to the body" do
        expect(activity.body).to eq("**Enquiry details**<br><br>Case is related to the coronavirus outbreak.<br><br>#{enquiry.description}<br><br>Case owner: #{enquiry.assignable.decorate.display_name}")
      end
    end
  end
end
