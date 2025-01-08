require "rails_helper"

RSpec.describe ChangeBusinessNames, :with_test_queue_adapter do
  subject(:result) { described_class.call!(trading_name:, legal_name:, notification:, business:, user:) }

  let!(:notification) { create(:notification, creator: user) }
  let!(:business) { create(:business, trading_name: previous_trading_name, legal_name: previous_legal_name) }
  let(:previous_trading_name) { "Old trading name" }
  let(:previous_legal_name) { "Old legal name" }
  let(:trading_name) { "Trading name" }
  let(:legal_name) { "Legal name" }
  let(:user) { create(:user, :activated) }

  context "with no trading name" do
    subject(:result) { described_class.call(legal_name:, notification:, business:, user:) }

    it "fails" do
      expect(result).to be_failure
    end
  end

  context "when the previous and the new names are the same" do
    subject(:result) { described_class.call!(trading_name: previous_trading_name, legal_name: previous_legal_name, notification:, business:, user:) }

    it "succeeds" do
      expect(result).to be_success
    end

    it "does not create a new activity" do
      expect {
        result
      }.not_to change(Activity, :count)
    end
  end

  context "when the previous names and the new names are different" do
    it "succeeds" do
      expect(result).to be_success
    end

    it "changes the trading_name for the notification" do
      expect { result }.to change(business, :trading_name).from(previous_trading_name).to(trading_name)
    end

    it "changes the legal_name for the notification" do
      expect { result }.to change(business, :legal_name).from(previous_legal_name).to(legal_name)
    end
  end
end
