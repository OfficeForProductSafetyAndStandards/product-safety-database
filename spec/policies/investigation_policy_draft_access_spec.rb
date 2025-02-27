require "rails_helper"

RSpec.describe InvestigationPolicy, :with_stubbed_mailer do
  describe "#can_access_draft?" do
    let(:user) { create(:user) }
    let(:policy) { described_class.new(user, notification) }

    context "when the notification is not a draft" do
      let(:notification) { instance_double(Investigation::Notification, draft?: false, is_a?: true) }

      it "returns true" do
        expect(policy.can_access_draft?).to be true
      end
    end

    context "when the record is not a notification" do
      let(:notification) { instance_double(Investigation, is_a?: false) }

      it "returns true" do
        expect(policy.can_access_draft?).to be true
      end
    end

    context "when the notification is a draft" do
      let(:notification) { instance_double(Investigation::Notification, draft?: true, is_a?: true, creator_user: creator_user, owner: owner) }
      let(:creator_user) { nil }
      let(:owner) { nil }

      context "when the user is the creator" do
        let(:creator_user) { user }

        it "returns true" do
          expect(policy.can_access_draft?).to be true
        end
      end

      context "when the user is the owner" do
        let(:owner) { user }

        it "returns true" do
          expect(policy.can_access_draft?).to be true
        end
      end

      context "when the user is neither the creator nor the owner" do
        let(:creator_user) { create(:user) }
        let(:owner) { create(:user) }

        it "returns false" do
          expect(policy.can_access_draft?).to be false
        end
      end
    end
  end
end
