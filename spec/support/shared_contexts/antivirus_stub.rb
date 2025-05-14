RSpec.shared_context "with stubbed antivirus" do
  before do
    antivirus_url = ENV["ANTIVIRUS_URL"] ? "#{ENV['ANTIVIRUS_URL'].chomp('/')}/v2/scan-chunked" : "https://staging.clamav.uktrade.digital/v2/scan-chunked"
    stub_request(:post, antivirus_url)
      .with(
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Authorization" => "Basic YXY6cGFzc3dvcmQ=",
          "Content-Type" => "multipart/form-data",
          "Host" => "localhost:3006",
          "User-Agent" => "Ruby"
        }
      )
      .to_return(status: 200, body: "", headers: {})
  end
end
