RSpec.configure do |config|
  config.before :each do
    elasticsearch_url = ENV.fetch('ELASTICSEARCH_URL', "http://elasticsearch:9200")
    stub_request(:any, /#{Regexp.quote(elasticsearch_url)}/).to_return(body: "Elasticsearch disabled in Rspec", status: 200)
  end
end
