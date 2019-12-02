RSpec.shared_context "with stubbed Antivirus", shared_context: :metadata do
  before do
    antivirus_url = ENV.fetch("ANTIVIRUS_URL", "http://elasticsearch:9200")
    stub_request(:any, /#{Regexp.quote(antivirus_url)}/).to_return(body: {safe: true}.to_json, status: 200)
  end
end

RSpec.configure do |rspec|
  rspec.include_context "with stubbed Antivirus", with_stubbed_antivirus: true
end
