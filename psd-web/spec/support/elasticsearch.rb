RSpec.shared_context "with stubbed Elasticsearch", shared_context: :metadata do
  before do
    elasticsearch_url = ENV.fetch("ELASTICSEARCH_URL", "http://elasticsearch:9200")
    stub_request(:any, /#{Regexp.quote(elasticsearch_url)}/).to_return(body: "Elasticsearch disabled in RSpec", status: 200)
  end
end

RSpec.configure do |rspec|
  rspec.include_context "with stubbed Elasticsearch", with_stubbed_elasticsearch: true
end
