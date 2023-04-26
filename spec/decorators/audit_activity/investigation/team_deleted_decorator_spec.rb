require "rails_helper"

RSpec.describe AuditActivity::Investigation::TeamDeletedDecorator, :with_stubbed_opensearch, :with_stubbed_mailer do
  subject(:activity) do
    AuditActivity::Investigation::TeamDeleted.create!(
      investigation:,
      metadata: described_class.build_metadata(team, message),
      added_by_user: user
    ).decorate
  end

  let(:investigation) { create(:allegation, creator: user) }
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let(:message) { "This is a message" }

  describe "#title" do
    it "returns a generated String" do
      expect(activity.title(user)).to eq("#{team.display_name} removed from case")
    end
  end

  describe "#subtitle" do
    it "returns a generated String" do
      expect(activity.subtitle(user)).to eq("Team removed by #{user.name}, #{Time.zone.today.to_formatted_s(:govuk)}")
    end
  end
end
