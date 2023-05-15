require "rails_helper"

RSpec.describe Investigation::RiskLevelChange do
  describe "#change_action" do
    subject(:change_action) do
      described_class.new(investigation).change_action
    end

    let(:current_level) { nil }
    let(:new_level) { nil }
    let(:levels) { Investigation.risk_levels }
    let(:investigation) do
      build_stubbed(:allegation, risk_level: current_level)
    end

    before do
      investigation.risk_level = new_level
    end

    context "when the risk level does not change" do
      it { is_expected.to be_nil }
    end

    context "when the risk level gets set" do
      let(:new_level) { levels[:high] }

      it { is_expected.to eq :set }
    end

    context "when the risk level changes" do
      let(:current_level) { levels[:low] }
      let(:new_level) { levels[:high] }

      it { is_expected.to eq :changed }
    end
  end
end
