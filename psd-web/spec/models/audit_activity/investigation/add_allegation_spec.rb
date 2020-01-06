require "rails_helper"

RSpec.describe AuditActivity::Investigation::AddAllegation, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  let(:allegation) { create(:allegation) }

  subject do
    allegation.activities.find_by!(type: described_class.name)
  end

  describe "#build_title" do
    it "stores the title" do
      expect(subject.title).to eq("Allegation logged: #{allegation.decorate.title}")
    end
  end

  describe "#build_body" do
    it "stores the body" do
      expect(subject.body).to eq("**Allegation details**<br><br>Hazard type: **#{allegation.hazard_type}**<br><br>#{allegation.description}<br><br>Assigned to #{allegation.assignee.display_name}.")
    end
  end
end
