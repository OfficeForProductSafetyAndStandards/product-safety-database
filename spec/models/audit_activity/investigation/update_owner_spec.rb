require "rails_helper"

RSpec.describe AuditActivity::Investigation::UpdateOwner, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:activity) { described_class.create(investigation: investigation, metadata: described_class.build_metadata(owner, rationale)) }

  let(:investigation) { create(:allegation, creator: create(:user, team: owner)) }
  let(:owner) { create(:team) }
  let(:rationale) { "Test rationale" }
  let(:user) { create(:user) }

  describe ".build_metadata" do
    let(:result) { described_class.build_metadata(owner, rationale) }

    it "returns a Hash of the arguments" do
      expect(result).to eq({
        owner_id: owner.id,
        rationale: rationale
      })
    end
  end

  describe "#title" do
    it "returns a generated String" do
      expect(activity.title(user)).to eq("Case owner changed to #{owner.name}")
    end
  end

  describe "#body" do
    it "returns the rationale" do
      expect(activity.body).to eq("Test rationale")
    end
  end

  describe "#owner" do
    it "returns the owner" do
      expect(activity.owner).to eq(owner)
    end
  end
end
