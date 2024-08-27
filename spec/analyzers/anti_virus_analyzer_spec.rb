require "rails_helper"
require "webmock/rspec"

RSpec.describe AntiVirusAnalyzer do
  let(:blob) { create(:active_storage_blob, :with_file) }
  let(:analyzer) { described_class.new(blob) }
  let(:antivirus_url) { "http://example.com/scan" }

  before do
    allow(Rails.application.config).to receive(:antivirus_url).and_return(antivirus_url)

    env_vars = {
      "ANTIVIRUS_USERNAME" => "av",
      "ANTIVIRUS_PASSWORD" => "password",
      "TMPDIR" => "/tmp"
    }

    allow(ENV).to receive(:[]) do |key|
      env_vars[key]
    end

    stub_request(:post, antivirus_url).to_return(status: 200, body: { safe: true }.to_json)
  end

  describe ".accept?" do
    it "always returns true" do
      expect(described_class.accept?(blob)).to be true
    end
  end

  describe "#metadata" do
    context "when file download fails" do
      before do
        allow(analyzer).to receive(:download_blob_to_tempfile).and_raise(StandardError, "Download failed")
      end

      it "returns an error" do
        expect(analyzer.metadata).to eq({ error: "Failed to download blob: Download failed" })
      end
    end

    context "when file download succeeds" do
      context "when request is successful" do
        it "returns the scan result" do
          expect(analyzer.metadata).to eq({ safe: true })
        end
      end

      context "when request fails" do
        before do
          stub_request(:post, antivirus_url).to_return(status: 500)
        end

        it "returns an error" do
          expect(analyzer.metadata).to eq({ error: "HTTP request failed with status 500" })
        end
      end

      context "when JSON parsing fails" do
        before do
          stub_request(:post, antivirus_url).to_return(status: 200, body: "Invalid JSON")
        end

        it "returns an error" do
          expect(analyzer.metadata).to eq({ error: "Invalid JSON response" })
        end
      end

      context "when request times out" do
        before do
          stub_request(:post, antivirus_url).to_timeout
        end

        it "returns an error" do
          expect(analyzer.metadata).to eq({ error: "An unexpected error occurred: execution expired" })
        end
      end
    end
  end
end
