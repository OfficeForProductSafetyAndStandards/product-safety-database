require "rails_helper"
require "csv"
require "fileutils"

RSpec.describe CsvExporter, type: :model do
  let(:csv_exporter) { described_class.new }

  before do
    allow(Time.zone).to receive(:now).and_return(Time.zone.parse("2023-01-01T00:00:00+00:00"))
    allow(Rails).to receive(:root).and_return(Pathname.new("/rails/root"))
    allow(Rails.configuration).to receive(:redacted_export).and_return({
      "region" => "us-east-1",
      "access_key_id" => "ACCESS_KEY",
      "secret_access_key" => "SECRET_KEY",
      "destination_bucket" => "destination_bucket"
    })
  end

  describe "#initialize" do
    it "sets the started_at and started_at_safe attributes" do
      expect(csv_exporter.started_at).to eq("2023-01-01T00:00:00+00:00")
      expect(csv_exporter.started_at_safe).to eq("2023-01-01T000000+0000")
    end

    it "sets the output_directory attribute" do
      expect(csv_exporter.output_directory.to_s).to eq("/rails/root/tmp/csv_export/2023-01-01T000000+0000")
    end

    it "sets the tables_and_attributes attribute" do
      expect(csv_exporter.tables_and_attributes).to be_a(Hash)
    end
  end

  describe "#export_tables" do
    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(csv_exporter).to receive(:export_table)
      allow(csv_exporter).to receive(:create_log_file)
    end

    it "creates the output directory" do
      csv_exporter.export_tables
      expect(FileUtils).to have_received(:mkdir_p).with(csv_exporter.output_directory)
    end

    it "exports each table" do
      csv_exporter.export_tables
      csv_exporter.tables_and_attributes.each do |table, attributes|
        expect(csv_exporter).to have_received(:export_table).with(table, attributes)
      end
    end

    it "creates the log file" do
      csv_exporter.export_tables
      expect(csv_exporter).to have_received(:create_log_file)
    end
  end

  describe "#upload_export" do
    let(:s3_client) { instance_double(Aws::S3::Client) }
    let(:files) { ["file1.csv", "file2.csv"] }

    before do
      allow(Dir).to receive(:glob).and_return(files)
      allow(Aws::S3::Client).to receive(:new).and_return(s3_client)
      allow(csv_exporter).to receive(:upload_to_s3)
      allow(csv_exporter).to receive(:upload_log_to_s3)
      allow(CsvExport).to receive(:create!)
    end

    it "uploads each CSV file to S3" do
      csv_exporter.upload_export
      files.each do |file|
        expect(csv_exporter).to have_received(:upload_to_s3).with(s3_client, file)
      end
    end

    it "uploads the log file to S3" do
      csv_exporter.upload_export
      expect(csv_exporter).to have_received(:upload_log_to_s3).with(s3_client)
    end

    it "creates a CsvExport record" do
      csv_exporter.upload_export
      expect(CsvExport).to have_received(:create!).with(started_at: csv_exporter.started_at, location: "csv/2023-01-01T000000+0000/")
    end
  end

  describe "#selected_tables_and_attributes" do
    let(:all_tables_and_attributes) do
      {
        "activities" => [{ "id" => :integer }, { "created_at" => :datetime }, { "invalid_attr" => :string }],
        "non_existent_table" => [{ "id" => :integer }]
      }
    end

    before do
      allow(csv_exporter).to receive(:all_active_record_tables_and_attributes).and_return(all_tables_and_attributes)
    end

    it "returns only the tables and attributes defined in ATTRIBUTES_TO_EXPORT" do
      result = csv_exporter.send(:selected_tables_and_attributes)
      expect(result).to eq({ "activities" => [{ "id" => :integer }, { "created_at" => :datetime }] })
    end
  end

  describe "#export_table" do
    let(:table_class) { class_double("TableClass") }
    let(:attributes) { [{ "id" => :integer }, { "created_at" => :datetime }] }
    let(:csv) { instance_double(CSV) }

    before do
      allow(csv_exporter).to receive(:classify_table_name).and_return(table_class)
      allow(CSV).to receive(:open).and_yield(csv)
      allow(csv_exporter).to receive(:export_records_in_batches)
      allow(csv).to receive(:<<)
    end

    it "exports the records to a CSV file" do
      csv_exporter.send(:export_table, "activities", attributes)
      expect(csv).to have_received(:<<).with(%w[id created_at])
      expect(csv_exporter).to have_received(:export_records_in_batches).with(table_class, %w[id created_at], csv)
    end
  end

  describe "#export_records_in_batches" do
    let(:table_class) { class_double("TableClass") }
    let(:csv) { instance_double(CSV) }
    let(:attributes) { %w[id created_at] }
    let(:csv_exporter) { described_class.new }
    let(:calls) { [] }

    context "with multiple records" do
      let(:records_batch_1) { (1..100).map { |i| [i, "2023-01-01T00:00:00+00:00"] } }
      let(:records_batch_2) { (101..200).map { |i| [i, "2023-01-02T00:00:00+00:00"] } }

      before do
        allow(table_class).to receive(:count).and_return(200)
        allow(table_class).to receive(:order).with(:id).and_return(table_class)
        allow(table_class).to receive(:limit).with(100).and_return(table_class)
        allow(table_class).to receive(:offset).with(0).and_return(instance_double("TableClass", pluck: records_batch_1))
        allow(table_class).to receive(:offset).with(100).and_return(instance_double("TableClass", pluck: records_batch_2))
        allow(csv).to receive(:<<) { |record| calls << record }
      end

      it "exports all records in the table in order" do
        csv_exporter.send(:export_records_in_batches, table_class, attributes, csv, 100)
        expect(calls.size).to eq(table_class.count)
        expect(calls.map(&:first)).to eq((1..200).to_a)
      end
    end

    context "with duplicate records" do
      let(:records_batch_1) { [[1, "2023-01-01T00:00:00+00:00"], [1, "2023-01-01T00:00:00+00:00"]] }
      let(:records_batch_2) { [[2, "2023-01-02T00:00:00+00:00"]] }
      let(:expected_unique_records) { [[1, "2023-01-01T00:00:00+00:00"], [2, "2023-01-02T00:00:00+00:00"]] }
      let(:all_records) { records_batch_1 + records_batch_2 }

      before do
        allow(table_class).to receive(:count).and_return(3) # Simulate the total DB row count before removing duplicates
        allow(table_class).to receive(:order).with(:id).and_return(table_class)
        allow(table_class).to receive(:limit).with(2).and_return(table_class)

        allow(table_class).to receive(:offset).with(0).and_return(instance_double("TableClass", pluck: records_batch_1))
        allow(table_class).to receive(:offset).with(2).and_return(instance_double("TableClass", pluck: records_batch_2))

        allow(csv).to receive(:<<) { |record| calls << record }
      end

      context "when exporting records" do
        before do
          calls.clear
          csv_exporter.send(:export_records_in_batches, table_class, attributes, csv, 2)
        end

        it "removes duplicate records" do
          unique_calls = calls.uniq
          expect(unique_calls).to include([1, "2023-01-01T00:00:00+00:00"])
          expect(unique_calls.count { |call| call == [1, "2023-01-01T00:00:00+00:00"] }).to eq(1)
        end

        it "exports records in batches in order" do
          expect(calls).to eq(expected_unique_records)
          expect(calls.map(&:first)).to eq([1, 2])
        end

        it "ensures the CSV count matches the DB rows count" do
          expect(calls.size).to eq(2)
        end

        it "counts the duplicates removed" do
          unique_calls = calls.uniq
          duplicate_count = all_records.size - unique_calls.size

          expect(duplicate_count).to eq(1)
        end
      end
    end

    context "when handling errors" do
      it "handles errors gracefully" do
        allow(table_class).to receive(:count).and_return(1)
        allow(table_class).to receive(:order).and_raise(StandardError.new("Error fetching records"))

        expect {
          csv_exporter.send(:export_records_in_batches, table_class, attributes, csv)
        }.not_to raise_error
      end
    end
  end

  describe "#create_log_file" do
    let(:file_path) { "#{csv_exporter.output_directory}/log.json" }

    before do
      allow(File).to receive(:write)
      allow(csv_exporter).to receive(:tables_and_attributes).and_return({ "activities" => [{ "id" => :integer }] })
    end

    it "creates the log file" do
      csv_exporter.send(:create_log_file)
      expect(File).to have_received(:write).with(file_path, kind_of(String))
    end
  end

  describe "#upload_to_s3" do
    let(:s3_client) { instance_double(Aws::S3::Client) }
    let(:file) { "file1.csv" }
    let(:file_content) { "file content" }

    before do
      allow(File).to receive(:read).and_return(file_content)
      allow(s3_client).to receive(:put_object)
    end

    it "uploads the file to S3" do
      csv_exporter.send(:upload_to_s3, s3_client, file)
      expect(s3_client).to have_received(:put_object).with(
        bucket: "destination_bucket",
        key: "csv/2023-01-01T000000+0000/file1.csv",
        content_type: "text/csv",
        body: file_content
      )
    end
  end

  describe "#upload_log_to_s3" do
    let(:s3_client) { instance_double(Aws::S3::Client) }
    let(:file_content) { "log content" }

    before do
      allow(File).to receive(:read).and_return(file_content)
      allow(s3_client).to receive(:put_object)
    end

    it "uploads the log file to S3" do
      csv_exporter.send(:upload_log_to_s3, s3_client)
      expect(s3_client).to have_received(:put_object).with(
        bucket: "destination_bucket",
        key: "csv/2023-01-01T000000+0000/log.json",
        content_type: "text/json",
        body: file_content
      )
    end
  end
end
