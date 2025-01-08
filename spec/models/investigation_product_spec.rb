require "rails_helper"

RSpec.describe InvestigationProduct, :with_stubbed_mailer, :with_stubbed_notify, :with_stubbed_opensearch do
  subject(:investigation_product) { create(:investigation_product) }

  it "has a valid factory" do
    expect(investigation_product).to be_valid
  end

  describe "#ucr_numbers" do
    subject { investigation_product.ucr_numbers }

    let(:investigation_product) { create(:investigation_product) }

    context "when there are no ucr_numbers" do
      it { is_expected.to be_empty }
    end

    context "when there are ucr_codes" do
      let(:investigation_product) { create(:investigation_product, :with_ucr_numbers) }

      it { is_expected.to be_present }
    end
  end
end
