require "rails_helper"

RSpec.describe AuditActivity::Investigation::TeamDeleted, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:activity) do
    described_class.create(
      investigation: investigation,
      metadata: described_class.build_metadata(team, message),
      source: UserSource.new(user: user)
    )
  end

  let(:investigation) { create(:allegation, creator: user) }
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let(:message) { "This is a message" }

  describe ".build_metadata" do
    let(:result) { described_class.build_metadata(team, message) }

    it "returns a Hash of the arguments" do
      expect(result).to eq({
        team: {
          id: team.id,
          name: team.display_name
        },
        message: message
      })
    end
  end

  describe "#title" do
    it "returns a generated String" do
      expect(activity.title(user)).to eq("#{team.display_name} removed from allegation")
    end
  end

  describe "#subtitle" do
    it "returns a generated String" do
      expect(activity.subtitle(user)).to eq("Team removed by #{user.name}, #{Time.zone.today.to_s(:govuk)}")
    end
  end
end
