RSpec.shared_context "with stubbed Antivirus API", shared_context: :metadata do
  before do
    antivirus_url = ENV["ANTIVIRUS_URL"] ? "#{ENV['ANTIVIRUS_URL'].chomp('/')}/v2/scan-chunked" : "http://localhost:3000/v2/scan-chunked"
    stubbed_response = JSON.generate(infected: false)
    stub_request(
      :any, /#{Regexp.quote(antivirus_url)}/
    ).to_return(
      body: stubbed_response,
      status: 200,
      headers: { "Content-Type" => "application/json" }
    )
  end
end

RSpec.shared_context "with stubbed failing Antivirus API", shared_context: :metadata do
  before do
    antivirus_url = ENV["ANTIVIRUS_URL"] ? "#{ENV['ANTIVIRUS_URL'].chomp('/')}/v2/scan-chunked" : "http://localhost:3000/v2/scan-chunked"
    stubbed_response = JSON.generate(infected: true)
    stub_request(
      :any, /#{Regexp.quote(antivirus_url)}/
    ).to_return(
      body: stubbed_response,
      status: 200,
      headers: { "Content-Type" => "application/json" }
    )
  end
end

RSpec.configure do |rspec|
  rspec.include_context "with stubbed Antivirus API", with_stubbed_antivirus: true
  rspec.include_context "with stubbed failing Antivirus API", with_stubbed_failing_antivirus: true
end
