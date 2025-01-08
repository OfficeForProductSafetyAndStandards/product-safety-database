require "rails_helper"

RSpec.describe AddImtToNotification, :with_stubbed_mailer do
  let(:user) { create(:user) }
  let(:notification) { create(:notification, risk_level:) }
  let(:team) { create(:team, name: "OPSS Incident Management") }
  let(:risk_level) { "serious" }
  let(:corrective_actions) { [] }

  before do
    allow(notification).to receive(:corrective_actions).and_return(corrective_actions)
    allow(AddTeamToNotification).to receive(:call!)
    allow(Team).to receive(:find_by).with(name: "OPSS Incident Management").and_return(team)
  end

  describe ".call" do
    subject(:result) { described_class.call(notification:, user:) }

    context "when notification is not supplied" do
      let(:notification) { nil }

      it "fails with an error" do
        expect(result).to be_a_failure
        expect(result.error).to eq("No notification supplied")
      end
    end

    context "when user is not supplied" do
      let(:user) { nil }

      it "fails with an error" do
        expect(result).to be_a_failure
        expect(result.error).to eq("No user supplied")
      end
    end

    context "when risk level is low and no relevant corrective action" do
      let(:risk_level) { "low" }
      let(:corrective_actions) { [instance_double(CorrectiveAction, action: "some_other_action")] }

      before do
        allow(corrective_actions).to receive(:pluck).with("action").and_return(corrective_actions.map(&:action))
      end

      it "does not add OPSS IMT team to the notification" do
        described_class.call(notification:, user:)
        expect(AddTeamToNotification).not_to have_received(:call!)
      end
    end

    context "when team is not found" do
      before do
        allow(Team).to receive(:find_by).with(name: "OPSS Incident Management").and_return(nil)
      end

      it "does not add OPSS IMT team to the notification" do
        described_class.call(notification:, user:)
        expect(AddTeamToNotification).not_to have_received(:call!)
      end
    end

    context "when risk level is serious or high" do
      before do
        described_class.call(notification:, user:)
      end

      it "adds OPSS IMT team to the notification" do
        expect(AddTeamToNotification).to have_received(:call!).with(
          notification:,
          team:,
          collaboration_class: Collaboration::Access::Edit,
          user:,
          message: "System added OPSS IMT with edit permissions due to either risk level or corrective action."
        )
      end

      it "is successful" do
        expect(result).to be_a_success
      end
    end

    context "when corrective action indicates a recall" do
      let(:risk_level) { "low" }
      let(:corrective_actions) { [create(:corrective_action, action: "recall_of_the_product_from_end_users")] }

      before do
        allow(notification).to receive(:corrective_actions).and_return(corrective_actions)
        allow(corrective_actions).to receive(:pluck).with("action").and_return(corrective_actions.map(&:action))
        described_class.call(notification:, user:)
      end

      it "adds OPSS IMT team to the notification" do
        expect(AddTeamToNotification).to have_received(:call!).with(
          notification:,
          team:,
          collaboration_class: Collaboration::Access::Edit,
          user:,
          message: "System added OPSS IMT with edit permissions due to either risk level or corrective action."
        )
      end

      it "is successful" do
        expect(result).to be_a_success
      end
    end

    context "when corrective action indicates a modification programme" do
      let(:risk_level) { "low" }
      let(:corrective_actions) { [create(:corrective_action, action: "modification_programme")] }

      before do
        allow(notification).to receive(:corrective_actions).and_return(corrective_actions)
        allow(corrective_actions).to receive(:pluck).with("action").and_return(corrective_actions.map(&:action))
        described_class.call(notification:, user:)
      end

      it "adds OPSS IMT team to the notification" do
        expect(AddTeamToNotification).to have_received(:call!).with(
          notification:,
          team:,
          collaboration_class: Collaboration::Access::Edit,
          user:,
          message: "System added OPSS IMT with edit permissions due to either risk level or corrective action."
        )
      end

      it "is successful" do
        expect(result).to be_a_success
      end
    end
  end
end
