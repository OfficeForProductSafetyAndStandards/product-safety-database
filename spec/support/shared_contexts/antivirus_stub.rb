RSpec.shared_context "with stubbed antivirus" do
  before do
    stub_request(:post, "http://localhost:3006/safe")
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
