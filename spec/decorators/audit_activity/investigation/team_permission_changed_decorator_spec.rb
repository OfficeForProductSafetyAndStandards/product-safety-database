require "rails_helper"

RSpec.describe AuditActivity::Investigation::TeamPermissionChangedDecorator, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:activity) do
    AuditActivity::Investigation::TeamPermissionChanged.create!(
      investigation: investigation,
      metadata: described_class.build_metadata(team, old_permission, new_permission, message),
      source: UserSource.new(user: user)
    ).decorate
  end

  let(:investigation) { create(:allegation, creator: user) }
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let(:message) { "This is a message" }
  let(:old_permission) { "readonly" }
  let(:new_permission) { "edit" }

  describe "#title" do
    it "returns a generated String" do
      expect(activity.title(user)).to eq("#{team.display_name}'s case permission level changed")
    end
  end

  describe "#subtitle" do
    it "returns a generated String" do
      expect(activity.subtitle(user)).to eq("Case permissions updated by #{user.name}, #{Time.zone.today.to_s(:govuk)}")
    end
  end

  describe "#new_permission" do
    it "returns a generated String" do
      expect(activity.new_permission).to eq("edit full case")
    end
  end

  describe "#old_permission" do
    it "returns a generated String" do
      expect(activity.old_permission).to eq("view full case")
    end
  end
end
