RSpec.shared_context "with stubbed Antivirus API", shared_context: :metadata do
  before do
    antivirus_url = Rails.application.config.antivirus_url
    stubbed_response = JSON.generate(safe: true)
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
    antivirus_url = Rails.application.config.antivirus_url
    stubbed_response = JSON.generate(safe: false)
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
