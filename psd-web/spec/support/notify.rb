# frozen_string_literal: true

RSpec.shared_context "with stubbed notify" do
  before do
    stub_request(:post, "https://api.notifications.service.gov.uk/v2/notifications/sms").
      and_return(body: {}.to_json)
  end
end

RSpec.configure do |rspec|
  rspec.include_context "with stubbed notify", :with_stubbed_notify
end
