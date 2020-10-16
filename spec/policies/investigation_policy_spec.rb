require "rails_helper"

RSpec.describe InvestigationPolicy, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:policy) { described_class.new(user, investigation) }

  let(:team) { create(:team) }
  let(:user) { create(:user, team: team) }

  context "when the investigation is not restricted" do
    let(:investigation) { create(:allegation, is_private: false) }

    context "when the user’s team has not been added to the case" do
      it "cannot update the case" do
        expect(policy.update?).to be false
      end

      it "cannot change case owner or status" do
        expect(policy.change_owner_or_status?).to be false
      end

      it "cannot manage collaborators" do
        expect(policy.manage_collaborators?).to be false
      end

      it "can view non-protected details" do
        expect(policy.view_non_protected_details?).to be true
      end

      it "cannot view all details about the case" do
        expect(policy.view_protected_details?).to be false
      end
    end

    context "when the user’s has been given read-only access" do
      before do
        create(:read_only_collaboration, investigation: investigation, collaborator: team)
      end

      it "cannot update the case" do
        expect(policy.update?).to be false
      end

      it "cannot change case owner or status" do
        expect(policy.change_owner_or_status?).to be false
      end

      it "cannot manage collaborators" do
        expect(policy.manage_collaborators?).to be false
      end

      it "can view non-protected details" do
        expect(policy.view_non_protected_details?).to be true
      end

      it "can view all details about the case" do
        expect(policy.view_protected_details?).to be true
      end

      it "is readonly" do
        expect(policy.readonly?).to be true
      end
    end

    context "when the user’s has been given edit access" do
      before do
        create(:collaboration_edit_access, investigation: investigation, collaborator: team)
      end

      it "can update the case" do
        expect(policy.update?).to be true
      end

      it "cannot change case owner or status" do
        expect(policy.change_owner_or_status?).to be false
      end

      it "cannot manage collaborators" do
        expect(policy.manage_collaborators?).to be false
      end

      it "can view non-protected details" do
        expect(policy.view_non_protected_details?).to be true
      end

      it "can view all details about the case" do
        expect(policy.view_protected_details?).to be true
      end

      it "is not readonly" do
        expect(policy.readonly?).to be false
      end
    end

    context "when the user’s team is the current case owner" do
      before do
        ChangeCaseOwner.call!(investigation: investigation, owner: team, user: create(:user))
      end

      it "can update the case" do
        expect(policy.update?).to be true
      end

      it "can change case owner or status" do
        expect(policy.change_owner_or_status?).to be true
      end

      it "can manage collaborators" do
        expect(policy.manage_collaborators?).to be true
      end

      it "can view non-protected details" do
        expect(policy.view_non_protected_details?).to be true
      end

      it "can view all details about the case" do
        expect(policy.view_protected_details?).to be true
      end

      it "is not readonly" do
        expect(policy.readonly?).to be false
      end
    end
  end

  context "when the investigation has been restricted" do
    let(:investigation) { create(:allegation, is_private: true) }

    context "when the user’s team has not been added to the case" do
      it "cannot update the case" do
        expect(policy.update?).to be false
      end

      it "cannot change case owner or status" do
        expect(policy.change_owner_or_status?).to be false
      end

      it "cannot manage collaborators" do
        expect(policy.manage_collaborators?).to be false
      end

      it "cannot view non-protected details" do
        expect(policy.view_non_protected_details?).to be false
      end

      it "cannot view all details about the case" do
        expect(policy.view_protected_details?).to be false
      end
    end
  end
end
