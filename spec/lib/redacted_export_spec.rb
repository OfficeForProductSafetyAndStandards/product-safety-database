RSpec.describe RedactedExport do
  describe ".register_model_attributes" do
    let(:table_name) { "test_models" }
    let(:model) { OpenStruct.new(table_name:) }
    let(:attributes) { %i[id updated_at created_at] }

    after do
      described_class.registry.delete table_name
    end

    it "adds attributes into the registry" do
      described_class.register_model_attributes model, *attributes
      expect(described_class.registry[table_name]).to eq(attributes)
    end

    it "merges attributes in multiple calls" do
      described_class.register_model_attributes model, *attributes
      described_class.register_model_attributes model, :name, :location
      expect(described_class.registry[table_name]).to eq(attributes + %i[name location])
    end

    it "deduplicates attributes" do
      duplicate_attributes = attributes + attributes + [:id]
      described_class.register_model_attributes model, *duplicate_attributes
      expect(described_class.registry[table_name]).to eq(attributes)
    end
  end

  describe ".register_table_attributes" do
    let(:table_name) { "test_models" }
    let(:attributes) { %i[id updated_at created_at] }

    after do
      described_class.registry.delete table_name
    end

    it "adds attributes into the registry" do
      described_class.register_table_attributes table_name, *attributes
      expect(described_class.registry[table_name]).to eq(attributes)
    end

    it "merges attributes in multiple calls" do
      described_class.register_table_attributes table_name, *attributes
      described_class.register_table_attributes table_name, :name, :location
      expect(described_class.registry[table_name]).to eq(attributes + %i[name location])
    end

    it "deduplicates attributes" do
      duplicate_attributes = attributes + attributes + [:id]
      described_class.register_table_attributes table_name, *duplicate_attributes
      expect(described_class.registry[table_name]).to eq(attributes)
    end
  end

  describe ".registry" do
    let(:table_name) { "non_existent_table" }

    it "returns nil for an unknown model" do
      expect(described_class.registry[table_name]).to eq(nil)
    end

    describe ".to_sql" do
      let(:model_table_name) { "test_models" }
      let(:model) { OpenStruct.new(table_name: model_table_name) }
      let(:model_attributes) { %i[id updated_at created_at] }
      let(:custom_table_name) { "test_custom" }
      let(:custom_attributes) { %i[name description] }

      before do
        described_class.register_model_attributes model, *model_attributes
        described_class.register_table_attributes custom_table_name, *custom_attributes
      end

      it "returns the correct SQL for models" do
        expect(described_class.registry.to_sql).to include("CREATE TABLE redacted.#{model_table_name} AS (SELECT #{model_attributes.join(', ')} FROM public.#{model_table_name});").once
      end

      it "returns the correct SQL for custom tables" do
        expect(described_class.registry.to_sql).to include("CREATE TABLE redacted.#{custom_table_name} AS (SELECT #{custom_attributes.join(', ')} FROM public.#{custom_table_name});").once
      end
    end
  end

  context "when included and used within a class" do
    subject!(:model) do
      Class.new do
        def self.table_name = "things"
        include RedactedExport
        redacted_export_with :test_1, :test_2, :test_3
      end
    end

    let(:table_name) { "things" }

    after do
      described_class.registry.delete table_name
    end

    describe ".redacted_export_with" do
      it "adds the attributes into the registry" do
        expect(described_class.registry[table_name]).to eq(%i[test_1 test_2 test_3])
      end
    end
  end
end
