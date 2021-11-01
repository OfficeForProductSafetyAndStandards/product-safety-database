require "rails_helper"

RSpec.describe RedactedExport do
  describe ".register_model_attributes" do
    let(:model) { Class.new }
    let(:attributes) { %i[id updated_at created_at] }

    after do
      described_class.registry.delete model
    end

    it "adds attributes into the registry" do
      described_class.register_model_attributes model, *attributes
      expect(described_class.registry[model]).to eq(attributes)
    end

    it "merges attributes in multiple calls" do
      described_class.register_model_attributes model, *attributes
      described_class.register_model_attributes model, :name, :location
      expect(described_class.registry[model]).to eq(attributes + %i[name location])
    end

    it "deduplicates attributes" do
      duplicate_attributes = attributes + attributes + [:id]
      described_class.register_model_attributes model, *duplicate_attributes
      expect(described_class.registry[model]).to eq(attributes)
    end
  end

  describe ".registry" do
    let(:model) { Class.new }

    it "returns a Hash" do
      expect(described_class.registry).to be_a(Hash)
    end

    it "returns nil for an unknown model" do
      expect(described_class.registry[model]).to eq(nil)
    end
  end

  context "when included and used within a class" do
    subject(:model) do
      Class.new do
        include RedactedExport
        redacted_export_with :test_1, :test_2, :test_3
      end
    end

    after do
      described_class.registry.delete model
    end

    describe ".redacted_export_with" do
      it "adds the attributes into the registry" do
        expect(described_class.registry[model]).to eq(%i[test_1 test_2 test_3])
      end
    end
  end
end
