require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe DeleteUnsafeFilesJob, type: :job do
  before do
    ActiveJob::Base.queue_adapter = :test
    Sidekiq::Testing.fake!
  end

  describe '#perform_later' do
    it 'adds job to the queue' do
      expect {
        DeleteUnsafeFilesJob.perform_later
      }.to have_enqueued_job(DeleteUnsafeFilesJob)
    end

    it 'adds job to specific queue' do
      expect {
        DeleteUnsafeFilesJob.perform_later
      }.to have_enqueued_job.on_queue(ENV["SIDEKIQ_QUEUE"] || "psd")
    end

    it 'changes queue size' do
      expect {
        DeleteUnsafeFilesJob.perform_later
      }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
    end
  end
end