require "rails_helper"

RSpec.describe InvestigationPolicy, :with_stubbed_mailer do
  subject(:policy) { described_class.new(user, notification) }

  let(:team) { create(:team) }
  let(:user) { create(:user, team:) }
  let(:creator_user) { create(:user, team:) }
  let(:other_user) { create(:user, team: create(:team)) }

  describe "#can_access_draft?" do
    context "when the record is not a notification" do
      let(:notification) { instance_double(Investigation::Allegation, is_a?: false) }

      it "returns true" do
        expect(policy.can_access_draft?).to be true
      end
    end

    context "when the notification is not a draft" do
      let(:notification) { instance_double(Investigation::Notification, is_a?: true, draft?: false) }

      it "returns true" do
        expect(policy.can_access_draft?).to be true
      end
    end

    context "when the notification is a draft" do
      context "when the user is the creator of the notification" do
        let(:notification) { instance_double(Investigation::Notification, is_a?: true, draft?: true, creator_user: user, owner: nil) }

        it "returns true" do
          expect(policy.can_access_draft?).to be true
        end
      end

      context "when the user is the owner of the notification" do
        let(:notification) { instance_double(Investigation::Notification, is_a?: true, draft?: true, creator_user: creator_user, owner: user) }

        it "returns true" do
          expect(policy.can_access_draft?).to be true
        end
      end

      context "when the user is neither the creator nor the owner" do
        let(:notification) { instance_double(Investigation::Notification, is_a?: true, draft?: true, creator_user: creator_user, owner: creator_user) }
        let(:user) { other_user }

        it "returns false" do
          expect(policy.can_access_draft?).to be false
        end
      end

      context "when the user is a super user" do
        let(:notification) { instance_double(Investigation::Notification, is_a?: true, draft?: true, creator_user: creator_user, owner: creator_user) }
        let(:user) { create(:user, :super_user) }

        it "returns false if they are not the creator or owner" do
          expect(policy.can_access_draft?).to be false
        end
      end
    end

    context "when the notification transitions from draft to submitted" do
      let(:notification) { create(:notification, creator_user:, state: "draft") }
      let(:user) { creator_user }

      it "allows access before and after submission" do
        # Before submission (draft)
        expect(policy.can_access_draft?).to be true

        # After submission
        notification.update!(state: "submitted")
        expect(policy.can_access_draft?).to be true
      end
    end
  end
end
