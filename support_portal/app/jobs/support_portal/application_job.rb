module SupportPortal
  class ApplicationJob < ActiveJob::Base
    queue_as ENV["SIDEKIQ_QUEUE"] || "psd"
  end
end
