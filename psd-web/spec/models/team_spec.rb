require "rails_helper"

RSpec.describe Team do
  describe ".all_with_organisation" do
    before { create_list(:team, 3) }

    let(:owners) { described_class.all_with_organisation }

    it "retrieves all teams" do
      expect(owners.length).to eq(3)
    end

    it "includes associations needed for display_name" do
      owners.length
      expect(lambda {
        owners.map(&:display_name)
      }).to not_talk_to_db
    end
  end

  describe ".get_visible_teams" do
    before do
      allow(Rails.application.config).to receive(:team_names).and_return(
        "organisations" => { "opss" => important_team_names }
      )

      org = Organisation.create!(name: "test")

      (important_team_names + %w[bobbins cribbins]).map do |name|
        described_class.create!(id: SecureRandom.uuid, name: name, organisation: org)
      end
    end

    let(:important_team_names) do
      %w[bish bosh bash]
    end

    context "with an OPSS user" do
      let(:user) { instance_double("User", is_opss?: true) }

      it "returns all important teams" do
        expect(described_class.get_visible_teams(user).map(&:name).to_set).to eq(important_team_names.to_set)
      end
    end

    context "with a non-OPSS user" do
      let(:user) { instance_double("User", is_opss?: false) }

      it "returns first important team" do
        expect(described_class.get_visible_teams(user).map(&:name)).to eq([important_team_names.first])
      end
    end
  end
end
