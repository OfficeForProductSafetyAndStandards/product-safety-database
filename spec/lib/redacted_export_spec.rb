require "rails_helper"

RSpec.describe RedactedExport do
  let(:dummy_class) do
    Class.new do
      def self.table_name
        "dummy_table"
      end

      include RedactedExport
    end
  end

  describe "class methods" do
    it "has an empty redacted_export_attributes array by default" do
      expect(dummy_class.redacted_export_attributes).to eq([])
    end

    it "registers model attributes" do
      dummy_class.send(:redacted_export_with, :attr1, :attr2)
      expect(described_class.registry["dummy_table"]).to include(:attr1, :attr2)
    end
  end

  describe RedactedExport::Registry do
    let(:registry) { described_class.new }

    describe "#register_model_attributes" do
      it "registers attributes for a model" do
        registry.register_model_attributes(dummy_class, :attr1, :attr2)
        expect(registry["dummy_table"]).to contain_exactly(:attr1, :attr2)
      end
    end

    describe "#register_table_attributes" do
      it "registers attributes for a table" do
        registry.register_table_attributes("custom_table", :attr1, :attr2)
        expect(registry["custom_table"]).to contain_exactly(:attr1, :attr2)
      end

      it "avoids duplicate attributes" do
        registry.register_table_attributes("custom_table", :attr1)
        registry.register_table_attributes("custom_table", :attr1, :attr2)
        expect(registry["custom_table"]).to contain_exactly(:attr1, :attr2)
      end
    end

    describe "#with_all_tables" do
      it "initializes all tables in the registry" do
        allow(ActiveRecord::Base.connection).to receive(:tables).and_return(%w[table1 table2])
        registry.with_all_tables
        expect(registry.keys).to include("table1", "table2")
      end
    end

    describe "#to_sql" do
      before do
        allow(Time.zone).to receive(:now).and_return(Time.new(2023, 7, 18, 0, 0, 0, "+00:00"))
        setup_registry_attributes
      end

      it "generates SQL for the registered tables and attributes" do
        expect(registry.to_sql).to eq(expected_sql)
      end

      def setup_registry_attributes
        registry.register_table_attributes("table1", "col1", "col2")
        registry.register_table_attributes("table2", "col3")
      end

      def expected_sql
        <<~SQL_OUTPUT
          --
          -- Redacted export generation SQL
          -- 2023-07-18 00:00:00 +0000
          --

          DROP SCHEMA IF EXISTS redacted CASCADE; CREATE SCHEMA redacted;

          CREATE TABLE redacted.table1 AS (SELECT col1, col2 FROM public.table1);

          CREATE TABLE redacted.table2 AS (SELECT col3 FROM public.table2);

          --
          -- Redacted export generation SQL complete
          --
        SQL_OUTPUT
      end
    end
  end
end
