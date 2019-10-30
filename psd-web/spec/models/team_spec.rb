require "rails_helper"

RSpec.describe Team do
  describe ".get_visible_teams" do
    before do
      allow(Rails.application.config).to receive(:team_names).and_return(
        "organisations" => { "opss" => important_team_names }
      )

      allow(described_class).to receive(:load).and_return(true)

      Team.data = (important_team_names + %w{bobbins cribbins}).map do |name|
        { name: name }
      end
    end

    let(:important_team_names) do
      %w{bish bosh bash}
    end

    context "OPSS user" do
      let(:user) { double("User", is_opss?: true) }

      it "returns all important teams" do
        expect(described_class.get_visible_teams(user).map(&:name)).to eq(important_team_names)
      end
    end

    context "Non-OPSS user" do
      let(:user) { double("User", is_opss?: false) }

      it "returns first important team" do
        expect(described_class.get_visible_teams(user).map(&:name)).to eq([important_team_names.first])
      end
    end
  end
end
