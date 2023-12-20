require "rails_helper"

RSpec.describe CreateNotification, :with_test_queue_adapter do
  let(:notification) { build(:notification) }
  let(:user) { create(:user) }
  let(:product) { create(:product) }
  let(:other_team) { create(:team) }

  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no notification parameter" do
      let(:result) { described_class.call(user:, product:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      let(:result) { described_class.call(notification:, product:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "when user is opss" do
      context "with no product parameter" do
        let(:result) { described_class.call(notification:, user:) }

        it "does not return a failure" do
          allow(user).to receive(:is_opss?).and_return(true)
          expect(result).to be_success
        end
      end
    end

    context "when user is not opss" do
      context "with no product parameter" do
        let(:result) { described_class.call(notification:, user:) }

        it "returns a failure" do
          expect(result).to be_failure
        end
      end
    end

    context "with required parameters" do
      let(:result) { described_class.call(notification:, user:, product:) }

      it "returns success" do
        expect(result).to be_success
      end

      context "when there is no creator user already on the notification" do
        before { notification.creator_user = nil }

        it "sets one" do
          result
          expect(notification.reload.creator_user).to eq(user)
        end
      end

      context "when there is no owner already on the notification" do
        before do
          notification.owner_user_collaboration = nil
          notification.owner_team_collaboration = nil
        end

        it "sets the owner to the user", :aggregate_failures do
          result

          notification.reload
          expect(notification.owner_user_collaboration.collaborator).to eq(user)
          expect(notification.owner_team_collaboration.collaborator).to eq(user.team)
        end
      end

      it "generates a pretty_id" do
        result
        expect(notification.reload.pretty_id).to be_a(String)
      end

      context "with previous notifications" do
        let(:notifications) { build_list(:notification, 3) }

        before { notifications.each { |i| described_class.call(notification: i, user:, product:) } }

        it "generates a successive pretty_id", :aggregate_failures do
          expect(Investigation.pluck(:pretty_id).map { |id| id.split("-").last }.sort)
            .to eq(%w[0001 0002 0003])
          result
          expect(notification.reload.pretty_id).to end_with("0004")
        end

        it "does not generate a conflicting pretty_id following a case deletion", :aggregate_failures do
          notifications.second.destroy!
          expect(Investigation.pluck(:pretty_id).map { |id| id.split("-").last })
            .to eq(%w[0001 0003])
          result
          expect(notification.reload.pretty_id).to end_with("0004")
        end
      end

      it "creates an audit activity for case created", :aggregate_failures do
        result
        activity = notification.reload.activities.first
        expect(activity).to be_a(AuditActivity::Investigation::AddCase)
        expect(activity.added_by_user).to eq(user)
        expect(activity.metadata).to eq(AuditActivity::Investigation::AddCase.build_metadata(notification).deep_stringify_keys)
      end

      context "when there are products added to the case" do
        let(:notification) { build(:allegation, creator: user) }
        let(:notification_product) { notification.investigation_products.first }

        it "creates an audit activity for product added", :aggregate_failures do
          result
          activity = notification.reload.activities.last
          expect(activity).to be_a(AuditActivity::Product::Add)
          expect(activity.added_by_user).to eq(user)
          expect(activity.investigation_product).to eq(notification_product)
          expect(activity.title(user)).to eq(product.name)
        end
      end

      it "sends a notification email to the notification creator" do
        expect { result }.to have_enqueued_mail(NotifyMailer, :notification_created).with(
          kind_of(String),
          user.name,
          user.email,
          "test notification title",
          "notification"
        ).once

      end

      context "when the product is previously unowned" do
        it "product becomes owned by the team of the user creating the notification" do
          result
          expect(product.reload.owning_team_id).to eq user.team.id
        end
      end

      context "when the product is already owned" do
        it "the product remains owned by the previous owner" do
          product.update!(owning_team_id: other_team.id)
          result
          expect(product.owning_team_id).to eq other_team.id
        end
      end
    end
  end
end
