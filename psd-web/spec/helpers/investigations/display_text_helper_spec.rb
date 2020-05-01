require "rails_helper"

RSpec.describe Investigations::DisplayTextHelper, type: :helper do
  describe "#investigation_owner", :with_stubbed_mailer, :with_stubbed_notify, :with_stubbed_elasticsearch do
    context "when owner has a team name that matches the organisation name" do
      let(:organisation) { create(:organisation, name: "Southampton Council") }
      let(:team) { create(:team, name: "Southampton Council", organisation: organisation) }
      let(:investigation) { create(:investigation, owner: team) }

      it "displays just the team name" do
        result = helper.investigation_owner(investigation)
        expect(result).to eq("Southampton Council")
      end
    end

    context "when owner has a team name differs from the organisation name" do
      let(:organisation) { create(:organisation, name: "Office for Product Safety and Standards") }
      let(:team) { create(:team, name: "OPSS Processing", organisation: organisation) }
      let(:investigation) { create(:investigation, owner: team) }

      it "displays the team name and the organisation name" do
        result = helper.investigation_owner(investigation)
        expect(result).to eq("OPSS Processing<br>Office for Product Safety and Standards")
      end
    end
  end
end
