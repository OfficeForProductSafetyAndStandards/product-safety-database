require "rails_helper"

RSpec.describe Team do
  describe ".get_visible_teams" do
    before do
      allow(Rails.application.config).to receive(:team_names).and_return(
        "organisations" => { "opss" => important_team_names }
      )

      org = Organisation.create!(name: "test")

      (important_team_names + %w[bobbins cribbins]).map do |name|
        described_class.create!(id: SecureRandom.uuid, name:, organisation: org, country: "country:GB")
      end
    end

    let(:important_team_names) do
      %w[bish bosh bash]
    end

    context "with an OPSS user" do
      let(:user) { instance_double(User, is_opss?: true) }

      it "returns all important teams" do
        expect(described_class.get_visible_teams(user).map(&:name).to_set).to eq(important_team_names.to_set)
      end
    end

    context "with a non-OPSS user" do
      let(:user) { instance_double(User, is_opss?: false) }

      it "returns first important team" do
        expect(described_class.get_visible_teams(user).map(&:name)).to eq([important_team_names.first])
      end
    end
  end

  describe ".not_deleted" do
    it "returns only teams without deleted timestamp" do
      create(:team, :deleted)
      not_deleted_team = create(:team)

      expect(described_class.not_deleted.to_a).to eq [not_deleted_team]
    end
  end

  describe "#mark_as_deleted!" do
    it "sets the team 'deleted_at' timestamp to the current time" do
      team = create(:team)
      freeze_time do
        expect { team.mark_as_deleted! }.to change { team.deleted_at }.from(nil).to(Time.zone.now)
      end
    end

    it "does not change the flag if was already enabled" do
      team = create(:team, :deleted)
      expect { team.mark_as_deleted! }.not_to change(team, :deleted_at)
    end
  end

  describe "#deleted?" do
    it "returns true for teams with deleted timestamp" do
      team = create(:team, :deleted)
      expect(team).to be_deleted
    end

    it "returns false for teams without deleted timestamp" do
      team = create(:team)
      expect(team).not_to be_deleted
    end
  end

  describe "#users_alphabetically_with_users_without_names_first" do
    let(:team) { create(:team) }

    before do
      create(:user, team:, name: "Alan Smith")
      create(:user, team:, name: "Bill Benjamin")
      create(:user, team:, name: "Xavier Johnson")
      create(:user, team:, name: nil)
    end

    it "returns ordered users" do
      ordered_team_names = team.users_alphabetically_with_users_without_names_first.map(&:name)
      expect(ordered_team_names).to eq ["", "Alan Smith", "Bill Benjamin", "Xavier Johnson"]
    end
  end
end
