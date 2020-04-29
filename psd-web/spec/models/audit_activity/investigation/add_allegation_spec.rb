require "rails_helper"

RSpec.describe AuditActivity::Investigation::AddAllegation, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:activity) do
    allegation.activities.find_by!(type: described_class.name)
  end

  let(:allegation) { create(:allegation) }


  describe "#build_title" do
    it "stores the title" do
      expect(activity.title).to eq("Allegation logged: #{allegation.decorate.title}")
    end
  end

  describe "#build_body" do
    it "stores the body" do
      expect(activity.body).to eq("**Allegation details**<br><br>Hazard type: **#{allegation.hazard_type}**<br><br>#{allegation.description}<br><br>Case owner: #{allegation.owner.display_name}")
    end

    context "when case is coronavirus related" do
      let(:allegation) { create(:allegation, coronavirus_related: true) }

      it "adds text to the body" do
        expect(activity.body).to eq("**Allegation details**<br><br>Case is related to the coronavirus outbreak.<br>Hazard type: **#{allegation.hazard_type}**<br><br>#{allegation.description}<br><br>Case owner: #{allegation.owner.display_name}")
      end
    end
  end
end
