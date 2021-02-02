require "rails_helper"

RSpec.describe AuditActivity::Test::ResultDecorator, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus do
  subject(:activity) do
    AuditActivity::Test::Result.create!(
      investigation: test_result.investigation,
      product: test_result.product,
      metadata: described_class.build_metadata(test_result),
      source: UserSource.new(user: user)
    ).decorate
  end

  let(:test_result) { create(:test_result, result: :passed) }
  let(:user) { test_result.investigation.creator_user }

  describe "#title" do
    it "returns a string" do
      expect(activity.title).to match(/\A(Passed test|Failed test|Test result): #{test_result.product.name}\z/)
    end
  end

  describe "#date" do
    it "returns a formatted string" do
      expect(activity.date).to eq(test_result.date.to_s(:govuk))
    end
  end

  describe "#result" do
    it "returns a formatted string" do
      expect(activity.result).to eq("Passed")
    end
  end
end
