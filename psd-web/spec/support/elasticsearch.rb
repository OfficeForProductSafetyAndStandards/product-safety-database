RSpec.shared_context "with stubbed Elasticsearch", shared_context: :metadata do
  before do
    elasticsearch_url = ENV.fetch("ELASTICSEARCH_URL", "http://elasticsearch:9200")
    stub_request(:any, /#{Regexp.quote(elasticsearch_url)}/).to_return(body: "Elasticsearch disabled in Rspec", status: 200)
  end
end

RSpec.shared_context "with Elasticsearch", shared_context: :metadata do
  before { WebMock.disable_net_connect!(allow: ENV.fetch("ELASTICSEARCH_URL")) }
  after { WebMock.disable_net_connect! }
end

RSpec.configure do |rspec|
  rspec.include_context "with stubbed Elasticsearch", with_stubbed_elasticsearch: true
  rspec.include_context "with Elasticsearch", with_elasticsearch: true
end
