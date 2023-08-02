RSpec.shared_context "with stubbed Opensearch", shared_context: :metadata do
  before do
    uri = URI(ENV.fetch("OPENSEARCH_URL"))
    stub_request(:any, /#{Regexp.quote("#{uri.host}:#{uri.port}")}/)
      .to_return(body: { hits: { hits: [{ error: "Opensearch disabled in Rspec" }] } }.to_json, status: 200, headers: { "Content-Type" => "application/json" })
  end
end

RSpec.shared_context "with Opensearch", shared_context: :metadata do
  def clean_opensearch_indices!
    opensearch_models.each do |model|
      model.__elasticsearch__.delete_index!
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      # Ideally the index should not exist before the test run but this guards against unclean state
    end
  end

  def create_opensearch_indices!
    opensearch_models.each do |model|
      if model == Investigation
        model.__elasticsearch__.import scope: "not_deleted", force: true, refresh: :wait
      else
        model.__elasticsearch__.import force: true, refresh: :wait
      end
    end
  end

  def opensearch_models
    [Investigation]
  end

  before do
    uri = URI(ENV.fetch("OPENSEARCH_URL"))
    WebMock.disable_net_connect!(allow: "#{uri.host}:#{uri.port}")
    create_opensearch_indices!
  end

  after do
    clean_opensearch_indices!
    WebMock.disable_net_connect!
  end
end

RSpec.configure do |rspec|
  rspec.include_context "with stubbed Opensearch", with_stubbed_opensearch: true
  rspec.include_context "with Opensearch", with_opensearch: true
end
