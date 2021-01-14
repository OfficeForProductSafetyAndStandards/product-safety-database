require "rails_helper"

RSpec.describe AuditActivity::CorrectiveAction::BaseDecorator, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:decorated_activity) do
    described_class.decorate(
      AuditActivity::CorrectiveAction::Base.new(
        business: business,
        metadata: { corrective_action_id: corrective_action.id }
      )
    )
  end

  let(:business)          { create(:business) }
  let(:corrective_action) { create(:corrective_action, business: business) }

  describe "#trading_name" do
    specify { expect(decorated_activity.trading_name).to eq(business.trading_name) }
  end

  describe "#online_recall_information" do
    it "delegates to the helper online_recall_information_text_for" do
      expect(decorated_activity.online_recall_information).to match(corrective_action.online_recall_information)
    end
  end
end
