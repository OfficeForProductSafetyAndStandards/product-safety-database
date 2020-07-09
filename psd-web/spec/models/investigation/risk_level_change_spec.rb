require "rails_helper"

RSpec.describe Investigation::RiskLevelChange do
  describe "#change_action" do
    subject(:change_action) do
      described_class.new(investigation).change_action
    end

    let(:current_level) { nil }
    let(:current_custom) { nil }
    let(:new_level) { nil }
    let(:new_custom) { nil }
    let(:investigation) { build_stubbed(:allegation) }
    let(:available_levels) { Investigation.risk_levels.keys }

    before do
      investigation.risk_level = current_level
      investigation.custom_risk_level = current_custom
    end

    context "when the risk or custom levels do not change" do
      it { is_expected.to be_nil }
    end

    context "when the risk level changes from unset to a standard value" do
      let(:new_level) { available_levels.first }

      it { is_expected.to eq :set }
    end

    context "when the risk level changes from unset to a non standard value" do
      let(:new_level) { "Non standard value" }

      it { is_expected.to be_nil }
    end

    context "when the custom level changes from unset to any value" do
      let(:new_custom) { "Custom level" }

      it { is_expected.to eq :set }
    end

    context "when the risk level changes to a non standard value" do
      let(:current_level) { available_levels.last }
      let(:new_level) { "Non standard value" }

      it { is_expected.to be_nil }
    end

    context "when the risk level changes to a standard value" do
      let(:current_level) { available_levels.last }
      let(:new_level) { available_levels.first }

      it { is_expected.to eq :changed }
    end

    context "when the custom level changes to any value" do
      let(:current_custom) { "Custom level" }
      let(:new_custom) { "New custom level" }

      it { is_expected.to eq :changed }
    end

    context "when the risk level changes to unset" do
      let(:current_level) { available_levels.last }
      let(:new_level) { nil }

      context "with a custom level that does not change" do
        let(:current_custom) { "Custom level" }
        let(:new_custom) { current_custom }

        it { is_expected.to eq :changed }
      end

      context "with a custom level that changes" do
        let(:current_custom) { "Custom level" }
        let(:new_custom) { "New custom level" }

        it { is_expected.to eq :changed }
      end

      context "without a custom level" do
        it { is_expected.to eq :removed }
      end
    end

    context "when the custom level changes to unset" do
      let(:current_custom) { "Custom risk" }
      let(:new_custom) { nil }

      context "with a risk level that does not change" do
        let(:current_level) { available_levels.first }
        let(:new_level) { current_level }

        it { is_expected.to eq :changed }
      end

      context "with a risk level that changes" do
        let(:current_level) { available_levels.first }
        let(:new_level) { available_levels.last }

        it { is_expected.to eq :changed }
      end

      context "without a risk level" do
        it { is_expected.to eq :removed }
      end
    end
  end
end
