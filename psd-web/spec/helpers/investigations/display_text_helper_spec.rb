require "rails_helper"

RSpec.describe Investigations::DisplayTextHelper, type: :helper do
  describe "#investigation_owner", :with_stubbed_mailer, :with_stubbed_notify, :with_stubbed_elasticsearch do
    context "when the case owner is a user" do
      let(:team) { create(:team, name: "Southampton Council") }
      let(:user) { create(:user, team: team, name: "John Doe") }
      let(:investigation) { create(:allegation, owner: user) }

      it "displays their team name as well as their name" do
        result = helper.investigation_owner(investigation)
        expect(result).to eq("John Doe<br>Southampton Council")
      end
    end

    context "when the case owner is a team" do
      let(:team) { create(:team, name: "Southampton Council") }
      let(:investigation) { create(:allegation, owner: team) }

      it "displays the team name once" do
        result = helper.investigation_owner(investigation)
        expect(result).to eq("Southampton Council")
      end
    end
  end
end
