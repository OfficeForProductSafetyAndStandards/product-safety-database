require "rails_helper"

RSpec.describe InvestigationPolicy, :with_stubbed_mailer do
  subject(:policy) { described_class.new(user, notification) }

  let(:team) { create(:team) }
  let(:user) { create(:user, team:) }
  let(:notification) { create(:notification, is_private: false) }

  context "when the investigation is not restricted" do
    context "when the user's team has not been added to the case" do
      it "cannot update the case" do
        expect(policy.update?).to be false
      end

      it "cannot change case owner or status" do
        expect(policy.change_owner_or_status?).to be false
      end

      it "cannot unrestrict the case" do
        expect(policy.can_unrestrict?).to be false
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

    context "when the user's has been given read-only access" do
      before do
        create(:read_only_collaboration, investigation: notification, collaborator: team)
        notification.reload
      end

      it "cannot update the case" do
        expect(policy.update?).to be false
      end

      it "cannot change case owner or status" do
        expect(policy.change_owner_or_status?).to be false
      end

      it "cannot unrestrict the case" do
        expect(policy.can_unrestrict?).to be false
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

    context "when the user's has been given edit access" do
      before do
        create(:collaboration_edit_access, investigation: notification, collaborator: team)
        notification.reload
      end

      it "can update the case" do
        expect(policy.update?).to be true
      end

      it "cannot change case owner or status" do
        expect(policy.change_owner_or_status?).to be false
      end

      it "cannot unrestrict the case" do
        expect(policy.can_unrestrict?).to be false
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

    context "when the user's team is the current case owner" do
      before do
        ChangeNotificationOwner.call!(notification:, owner: team, user: create(:user))
      end

      it "can update the case" do
        expect(policy.update?).to be true
      end

      it "can change case owner or status" do
        expect(policy.change_owner_or_status?).to be true
      end

      it "cannot unrestrict the case" do
        expect(policy.can_unrestrict?).to be false
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

    context "when the user's team is the current case owner and the case is restricted" do
      before do
        ChangeNotificationOwner.call!(notification:, owner: team, user: create(:user))
        notification.update!(is_private: true)
        notification.reload
      end

      it "can update the case" do
        expect(policy.update?).to be true
      end

      it "can change case owner or status" do
        expect(policy.change_owner_or_status?).to be true
      end

      it "cannot unrestrict the case" do
        expect(policy.can_unrestrict?).to be true
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

    context "when the user is a super user" do
      let(:different_team) { create(:team) }
      let(:user) { create(:user, :super_user, team: different_team) }

      it "can update the case" do
        expect(policy.update?).to be true
      end

      it "can change case owner or status" do
        expect(policy.change_owner_or_status?).to be true
      end

      it "can unrestrict the case" do
        expect(policy.can_unrestrict?).to be true
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

      it "is readonly" do
        expect(policy.readonly?).to be false
      end

      it "can view the notifying country" do
        expect(policy.view_notifying_country?).to be true
      end

      it "can edit the notifying country" do
        expect(policy.change_notifying_country?).to be true
      end

      it "can view the overseas regulator" do
        expect(policy.view_overseas_regulator?).to be true
      end

      it "can edit the overseas regulator" do
        expect(policy.change_overseas_regulator?).to be true
      end
    end
  end

  context "when the notification has been closed" do
    let(:notification) { create(:notification, is_closed: true) }

    context "when the user is not a super user" do
      it "cannot update the case" do
        expect(policy.update?).to be false
      end
    end

    context "when the user is a super user" do
      let(:user) { create(:user, :super_user) }

      it "can update the case" do
        expect(policy.update?).to be true
      end
    end
  end

  context "when the notification has been restricted" do
    let(:notification) { create(:notification, is_private: true) }

    context "when the user's team has not been added to the case" do
      it "cannot update the case" do
        expect(policy.update?).to be false
      end

      it "cannot change case owner or status" do
        expect(policy.change_owner_or_status?).to be false
      end

      it "cannot unrestrict the case" do
        expect(policy.can_unrestrict?).to be false
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

      context "when the user has the restricted_case_viewer role" do
        let(:user) { create(:user, :restricted_case_viewer, team:) }

        it "can view non-protected details" do
          expect(policy.view_non_protected_details?).to be true
        end

        it "can view all details about the case" do
          expect(policy.view_protected_details?).to be true
        end
      end
    end

    context "when the user is a super user" do
      let(:different_team) { create(:team) }
      let(:user) { create(:user, :super_user, team: different_team) }

      it "can update the case" do
        expect(policy.update?).to be true
      end

      it "can change case owner or status" do
        expect(policy.change_owner_or_status?).to be true
      end

      it "can unrestrict the case" do
        expect(policy.can_unrestrict?).to be true
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

      it "can view the notifying country" do
        expect(policy.view_notifying_country?).to be true
      end

      it "can edit the notifying country" do
        expect(policy.change_notifying_country?).to be true
      end
    end
  end

  describe "#can_be_deleted?" do
    context "when notification has products" do
      let(:notification) { create(:allegation, :with_products, is_private: false) }

      it "returns false" do
        expect(policy.can_be_deleted?).to be false
      end
    end

    context "when notification does not have products" do
      it "returns true" do
        expect(policy.can_be_deleted?).to be true
      end
    end
  end
end
