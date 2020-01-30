RSpec.shared_context "with stubbed Elasticsearch", shared_context: :metadata do
  before do
    elasticsearch_url = ENV.fetch("ELASTICSEARCH_URL", "http://elasticsearch:9200")
    empty_elasticsearch_response = {
      took: 0,
      timed_out: false,
      _shards: { total: 0, successful: 1, skipped: 0, failed: 0 },
      hits: {
        total: 0,
        max_score: 0.0,
        hits: []
      }
    }
    stub_request(:any, /#{Regexp.quote(elasticsearch_url)}/).to_return(
      body: empty_elasticsearch_response.to_json,
      status: 200,
      headers: { "Content-Type" => "application/json" }
    )
  end
end

RSpec.shared_context "with Elasticsearch", shared_context: :metadata do
  def clean_elasticsearch_indices!
    elasticsearch_models.each do |model|
      begin
        model.__elasticsearch__.delete_index!
      rescue Elasticsearch::Transport::Transport::Errors::NotFound # rubocop:disable Lint/SuppressedException
        # Ideally the index should not exist before the test run but this guards against unclean state
      end
    end
  end

  def create_elasticsearch_indices!
    elasticsearch_models.each do |model|
      model.__elasticsearch__.create_index!
      model.__elasticsearch__.refresh_index!
    end
  end

  def elasticsearch_models
    ActiveRecord::Base.descendants.select { |model| model.respond_to?(:__elasticsearch__) && !model.superclass.respond_to?(:__elasticsearch__) }
  end

  before do
    WebMock.disable_net_connect!(allow: ENV.fetch("ELASTICSEARCH_URL"))
    create_elasticsearch_indices!
  end

  after do
    clean_elasticsearch_indices!
    WebMock.disable_net_connect!
  end
end

RSpec.configure do |rspec|
  rspec.include_context "with stubbed Elasticsearch", with_stubbed_elasticsearch: true
  rspec.include_context "with Elasticsearch", with_elasticsearch: true
end
