require "rails_helper"

RSpec.describe TeamDecorator do
  subject(:decorated_team) { team.decorate }

  let(:team) { build_stubbed(:team) }

  describe "#owner_short_name" do
    it { expect(decorated_team.owner_short_name).to eq(team.display_name) }
  end

  describe "#display_name" do
    it "returns the team name" do
      expect(decorated_team.display_name).to eq(team.name)
    end
  end
end
