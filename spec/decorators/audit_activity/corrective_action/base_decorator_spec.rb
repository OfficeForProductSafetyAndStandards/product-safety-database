RSpec.describe AuditActivity::CorrectiveAction::BaseDecorator, :with_stubbed_mailer do
  include ActionDispatch::TestProcess::FixtureFile

  subject(:decorated_activity) { described_class.decorate(AuditActivity::CorrectiveAction::Base.new(business:)) }

  let(:business) { create(:business) }

  describe "#trading_name" do
    specify { expect(decorated_activity.trading_name).to eq(business.trading_name) }
  end
end
