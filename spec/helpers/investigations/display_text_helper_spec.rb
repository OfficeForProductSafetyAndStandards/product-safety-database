require "rails_helper"

RSpec.describe Investigations::DisplayTextHelper, type: :helper do
  describe "#investigation_owner", :with_stubbed_mailer, :with_stubbed_notify, :with_stubbed_opensearch do
    context "when the case owner is a user" do
      let(:team) { create(:team, name: "Southampton Council") }
      let(:user) { create(:user, team:, name: "John Doe") }
      let(:notification) { create(:notification, creator: user) }

      it "displays their team name as well as their name" do
        result = helper.investigation_owner(investigation)
        expect(result).to eq("John Doe - Southampton Council")
      end
    end

    context "when the case owner is a team" do
      let(:team) { create(:team, name: "Southampton Council") }
      let(:notification) { create(:notification) }

      before do
        ChangeNotificationOwner.call!(notification:, owner: team, user: create(:user))
      end

      it "displays the team name once" do
        result = helper.investigation_owner(notification)
        expect(result).to eq("Southampton Council")
      end
    end
  end
end
