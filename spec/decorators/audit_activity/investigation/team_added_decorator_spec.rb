require "rails_helper"

RSpec.describe AuditActivity::Investigation::TeamAddedDecorator, :with_stubbed_mailer do
  subject(:activity) do
    AuditActivity::Investigation::TeamAdded.create!(
      investigation:,
      metadata: described_class.build_metadata(collaboration, message),
      added_by_user: user
    ).decorate
  end

  let(:investigation) { create(:allegation, creator: user, edit_access_teams: [team]) }
  let(:user) { create(:user) }
  let(:team) { create(:team) }

  let(:collaboration) { investigation.edit_access_collaborations.last }
  let(:message) { "This is a message" }

  describe "#title" do
    it "returns a generated String" do
      expect(activity.title(user)).to eq("#{team.display_name} added to case")
    end
  end

  describe "#subtitle" do
    it "returns a generated String" do
      expect(activity.subtitle(user)).to eq("Team added by #{user.name}, #{Time.zone.today.to_formatted_s(:govuk)}")
    end
  end

  describe "#permission" do
    it "returns a generated String" do
      expect(activity.permission).to eq("edit full case")
    end
  end
end
