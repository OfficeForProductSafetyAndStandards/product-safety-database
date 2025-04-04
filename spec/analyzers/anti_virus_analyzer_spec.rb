require "rails_helper"
require "webmock/rspec"

RSpec.describe AntiVirusAnalyzer do
  let(:blob) { create(:active_storage_blob, :with_file) }
  let(:analyzer) { described_class.new(blob) }
  let(:antivirus_url) { "http://example.com" }
  let(:antivirus_scan_url) { "#{antivirus_url}/v2/scan-chunked" }

  before do
    env_vars = {
      "ANTIVIRUS_URL" => antivirus_url,
      "ANTIVIRUS_USERNAME" => "av",
      "ANTIVIRUS_PASSWORD" => "password",
      "TMPDIR" => "/tmp"
    }

    allow(ENV).to receive(:[]) do |key|
      env_vars[key]
    end

    stub_request(:post, antivirus_scan_url)
      .with(
        headers: {
          "Content-Type" => "application/octet-stream",
          "Filename" => "file"
        }
      )
      .to_return(status: 200, body: { infected: false }.to_json)
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

        context "when the file is infected" do
          before do
            stub_request(:post, antivirus_scan_url)
              .with(
                headers: {
                  "Content-Type" => "application/octet-stream",
                  "Filename" => "file"
                }
              )
              .to_return(status: 200, body: { infected: true }.to_json)
          end

          it "returns file as unsafe" do
            expect(analyzer.metadata).to eq({ safe: false })
          end
        end
      end

      context "when request fails" do
        before do
          stub_request(:post, antivirus_scan_url)
            .with(
              headers: {
                "Content-Type" => "application/octet-stream",
                "Filename" => "file"
              }
            )
            .to_return(status: 500)
        end

        it "returns an error" do
          expect(analyzer.metadata).to eq({ error: "HTTP request failed with status 500" })
        end
      end

      context "when JSON parsing fails" do
        before do
          stub_request(:post, antivirus_scan_url)
            .with(
              headers: {
                "Content-Type" => "application/octet-stream",
                "Filename" => "file"
              }
            )
            .to_return(status: 200, body: "Invalid JSON")
        end

        it "returns an error" do
          expect(analyzer.metadata).to eq({ error: "Invalid JSON response" })
        end
      end

      context "when request times out" do
        before do
          stub_request(:post, antivirus_scan_url)
            .with(
              headers: {
                "Content-Type" => "application/octet-stream",
                "Filename" => "file"
              }
            )
            .to_timeout
        end

        it "returns an error" do
          expect(analyzer.metadata).to eq({ error: "An unexpected error occurred: execution expired" })
        end
      end
    end
  end
end
