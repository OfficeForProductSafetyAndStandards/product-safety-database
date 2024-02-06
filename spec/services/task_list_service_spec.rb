require "rails_helper"

describe TaskListService do
  describe ".previous_task" do
    subject(:result) { described_class.previous_task(task:, all_tasks:, optional_tasks:) }

    let(:all_tasks) { %w[read_manual setup tweak adjust frobnicate percussive_maintenance submission evaluation] }

    context "when there are no optional tasks" do
      let(:optional_tasks) { [] }
      let(:task) { "adjust" }

      it "returns the previous task" do
        expect(result).to eq("tweak")
      end

      context "when the supplied task is the first one" do
        let(:task) { "read_manual" }

        it "returns nil" do
          expect(result).to be_nil
        end
      end
    end

    context "when there are optional tasks" do
      let(:optional_tasks) { %w[read_manual adjust frobnicate] }

      context "when the supplied task is a mandatory one" do
        let(:task) { "percussive_maintenance" }

        it "returns the previous mandatory task" do
          expect(result).to eq("tweak")
        end
      end

      context "when the supplied task is the first mandatory one" do
        let(:task) { "setup" }

        it "returns nil" do
          expect(result).to be_nil
        end
      end

      context "when the supplied task is an optional one" do
        let(:task) { "frobnicate" }

        it "returns the previous mandatory task" do
          expect(result).to eq("tweak")
        end
      end

      context "when there are no mandatory tasks before the supplied task" do
        let(:optional_tasks) { %w[read_manual setup tweak] }
        let(:task) { "adjust" }

        it "returns nil" do
          expect(result).to be_nil
        end
      end
    end
  end
end
