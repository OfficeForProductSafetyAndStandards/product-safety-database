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

    # Set up a default successful response for RestClient
    stub_request(:post, antivirus_scan_url)
      .with(
        headers: {
          "Content-Type" => "application/octet-stream",
          "Transfer-Encoding" => "chunked",
          "Authorization" => "Basic YXY6cGFzc3dvcmQ="
        }
      )
      .to_return(status: 200, body: { malware: false, reason: nil, time: 0.001 }.to_json)
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
      # Mock the File operations to prevent actual file I/O
      before do
        file_double = instance_double(File, read: "Hello, World!", closed?: false, close: nil)
        allow(File).to receive(:new).and_return(file_double)
      end

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
                  "Transfer-Encoding" => "chunked",
                  "Authorization" => "Basic YXY6cGFzc3dvcmQ="
                }
              )
              .to_return(status: 200, body: { malware: true, reason: "Test-Virus-Found", time: 0.001 }.to_json)
          end

          it "returns file as unsafe" do
            expect(analyzer.metadata).to eq({ safe: false, message: "Test-Virus-Found" })
          end
        end
      end

      context "when request fails" do
        before do
          # Use RestClient::ExceptionWithResponse
          response = instance_double(RestClient::Response, code: 500, body: "Server Error")
          exception = RestClient::InternalServerError.new(response)
          allow(RestClient::Request).to receive(:execute).and_raise(exception)
        end

        it "returns an error" do
          result = analyzer.metadata
          expect(result[:safe]).to be(false)
          expect(result[:error]).to include("500 Internal Server Error")
        end
      end

      context "when JSON parsing fails" do
        before do
          stub_request(:post, antivirus_scan_url)
            .with(
              headers: {
                "Content-Type" => "application/octet-stream",
                "Transfer-Encoding" => "chunked",
                "Authorization" => "Basic YXY6cGFzc3dvcmQ="
              }
            )
            .to_return(status: 200, body: "Invalid JSON")
        end

        it "returns an error" do
          expect(analyzer.metadata[:safe]).to be(false)
          expect(analyzer.metadata[:error]).to include("unexpected token")
        end
      end

      context "when request times out" do
        before do
          # Use Timeout::Error instead of RestClient::Exceptions::OpenTimeout
          allow(RestClient::Request).to receive(:execute).and_raise(Timeout::Error.new("Connection timed out"))
        end

        it "returns an error" do
          result = analyzer.metadata
          expect(result[:safe]).to be(false)
          expect(result[:error]).to include("Connection timed out")
        end
      end
    end
  end
end
