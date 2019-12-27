RSpec.shared_context "with stubbed Antivirus API", shared_context: :metadata do
  before do
    antivirus_url = ENV.fetch("ANTIVIRUS_URL", "http://antivirus")
    stubbed_response = JSON.generate(safe: true)
    stub_request(:any, /#{Regexp.quote(antivirus_url)}/).to_return(body: stubbed_response, status: 200)
  end
end

RSpec.configure do |rspec|
  rspec.include_context "with stubbed Antivirus API", with_stubbed_antivirus: true
end
