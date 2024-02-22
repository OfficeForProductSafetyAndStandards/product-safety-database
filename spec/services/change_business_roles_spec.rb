require "rails_helper"

RSpec.describe ChangeBusinessRoles, :with_test_queue_adapter do
  subject(:result) { described_class.call!(roles:, online_marketplace_id:, new_online_marketplace_name:, authorised_representative_choice:, notification:, business:, user:) }

  let!(:notification) { create(:notification, creator: user) }
  let!(:business) { create(:business) }
  let(:roles) { %w[retailer manufacturer] }
  let(:online_marketplace_id) { nil }
  let(:online_marketplace) { create(:online_marketplace, :approved) }
  let(:new_online_marketplace_name) { nil }
  let(:authorised_representative_choice) { nil }
  let(:user) { create(:user, :activated) }

  context "with no roles" do
    subject(:result) { described_class.call(notification:, business:, user:) }

    it "fails" do
      expect(result).to be_failure
    end
  end

  context "with allowed roles" do
    it "passes" do
      expect(result).not_to be_failure
    end
  end

  context "with roles to be removed" do
    before { InvestigationBusiness.create(business:, investigation: notification, relationship: "exporter") }

    it "correctly removes the roles" do
      expect(InvestigationBusiness.where(business:, investigation: notification).pluck(:relationship)).to match(%w[exporter])

      result

      expect(InvestigationBusiness.where(business:, investigation: notification).pluck(:relationship)).to match_array(roles)
    end
  end

  context "with roles to be added" do
    before { InvestigationBusiness.create(business:, investigation: notification, relationship: "retailer") }

    it "correctly removes the roles" do
      expect(InvestigationBusiness.where(business:, investigation: notification).pluck(:relationship)).to match(%w[retailer])

      result

      expect(InvestigationBusiness.where(business:, investigation: notification).pluck(:relationship)).to match_array(roles)
    end
  end

  context "when adding an online marketplace" do
    let(:roles) { %w[online_marketplace] }

    context "with an existing online_marketplace_id" do
      let(:online_marketplace_id) { online_marketplace.id }

      it "creates a new InvestigationBusiness with that online marketplace" do
        expect {
          result
        }.to change(InvestigationBusiness.where(business:, investigation: notification, relationship: "online_marketplace", online_marketplace_id:), :count).by(1)
      end
    end

    context "with a new_online_marketplace_name" do
      let(:new_online_marketplace_name) { "New online marketplace" }

      it "creates a new, unapproved online marketplace" do
        expect {
          result
        }.to change(OnlineMarketplace.where(approved_by_opss: false), :count).by(1)
      end

      it "creates a new InvestigationBusiness with that online marketplace" do
        expect {
          result
        }.to change(InvestigationBusiness.where(business:, investigation: notification, relationship: "online_marketplace"), :count).by(1)
      end
    end
  end

  context "with role of authorised representative" do
    let(:roles) { %w[authorised_representative] }
    let(:authorised_representative_choice) { "uk_authorised_representative" }

    it "created a new InvestigatuonBusiness with the correct relationship" do
      expect {
        result
      }.to change(InvestigationBusiness.where(business:, investigation: notification, relationship: "uk_authorised_representative"), :count).by(1)
    end
  end
end
