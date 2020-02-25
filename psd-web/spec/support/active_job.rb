RSpec.configure do |config|
  config.around :each, :with_test_queue_adpater do |example|
    ActiveJob::Base.queue_adapter = :test
    example.run
    ActiveJob::Base.queue_adapter = :inline
  end
end
