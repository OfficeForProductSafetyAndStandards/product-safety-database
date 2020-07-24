require "rails_helper"

RSpec.describe AuditActivity::Investigation::TeamAdded, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:activity) do
    described_class.create(
      investigation: investigation,
      metadata: described_class.build_metadata(collaboration, message),
      source: UserSource.new(user: user)
    )
  end

  let(:investigation) { create(:allegation, creator: user, edit_access_teams: [team]) }
  let(:user) { create(:user) }
  let(:team) { create(:team) }

  let(:collaboration) { investigation.edit_access_collaborations.last }
  let(:message) { "This is a message" }

  describe ".build_metadata" do
    let(:result) { described_class.build_metadata(collaboration, message) }

    it "returns a Hash of the arguments" do
      expect(result).to eq({
        team: { id: team.id, name: team.display_name },
        permission: "edit",
        message: message
      })
    end
  end

  describe "#title" do
    it "returns a generated String" do
      expect(activity.title(user)).to eq("#{team.display_name} added to allegation")
    end
  end

  describe "#subtitle" do
    it "returns a generated String" do
      expect(activity.subtitle(user)).to eq("Team added by #{user.name}, #{Time.zone.today.to_s(:govuk)}")
    end
  end

  describe "#permission" do
    it "returns a generated String" do
      expect(activity.permission).to eq("edit full case")
    end
  end
end
