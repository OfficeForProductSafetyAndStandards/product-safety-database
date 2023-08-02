RSpec.configure do |rspec|
  rspec.include_context "with stubbed Opensearch", with_stubbed_opensearch: true
  rspec.include_context "with Opensearch", with_opensearch: true
end
