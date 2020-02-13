require "rails_helper"

RSpec.describe Team do
  describe ".all_with_organisation" do
    before { 3.times { create(:team) } }

    it "includes associations needed for display_name" do
      assignees = described_class.all_with_organisation

      expect(assignees.length).to eq(3)
      expect(-> {
        assignees.map(&:display_name)
      }).to not_talk_to_db
    end
  end

  describe ".get_visible_teams" do
    before do
      allow(Rails.application.config).to receive(:team_names).and_return(
        "organisations" => { "opss" => important_team_names }
      )

      org = Organisation.create!(id: SecureRandom.uuid, name: "test", path: "/test")

      (important_team_names + %w{bobbins cribbins}).map do |name|
        Team.create!(id: SecureRandom.uuid, name: name, organisation: org, path: "/test")
      end
    end

    let(:important_team_names) do
      %w{bish bosh bash}
    end

    context "OPSS user" do
      let(:user) { double("User", is_opss?: true) }

      it "returns all important teams" do
        expect(described_class.get_visible_teams(user).map(&:name).to_set).to eq(important_team_names.to_set)
      end
    end

    context "Non-OPSS user" do
      let(:user) { double("User", is_opss?: false) }

      it "returns first important team" do
        expect(described_class.get_visible_teams(user).map(&:name)).to eq([important_team_names.first])
      end
    end
  end

  describe "#display_name" do
    subject(:team) { create(:team, organisation: organisation) }

    let(:organisation) { create(:organisation) }

    let(:user_same_org) { create(:user, organisation: organisation) }
    let(:user_other_org) { create(:user) }

    let(:ignore_visibility_restrictions) { false }
    let(:result) { team.display_name(ignore_visibility_restrictions: ignore_visibility_restrictions, current_user: viewing_user) }

    context "with user of same organisation" do
      let(:viewing_user) { user_same_org }

      it "returns the team name" do
        expect(result).to eq(team.name)
      end
    end

    context "with user of another organisation" do
      let(:viewing_user) { user_other_org }

      context "with ignore_visibility_restrictions: true" do
        let(:ignore_visibility_restrictions) { true }

        it "returns the team name" do
          expect(result).to eq(team.name)
        end
      end

      context "with ignore_visibility_restrictions: false" do
        it "returns the organisation name" do
          expect(result).to eq(organisation.name)
        end
      end
    end
  end
end
