# frozen_string_literal: true

RSpec.shared_context "with stubbed notify" do
  before do
    allow(Rails.application.config)
      .to receive(:notify_api_key)
      .and_return("fake_test_key-b1dbb0f5-4651-4af8-9f15-fa8123ff138d-3df264a8-ed9e-381f-b1f3-c3278411adbc")
    stub_request(:post, "https://api.notifications.service.gov.uk/v2/notifications/sms").
      and_return(body: {}.to_json)
  end
end

RSpec.configure do |rspec|
  rspec.include_context "with stubbed notify", :with_stubbed_notify
end
