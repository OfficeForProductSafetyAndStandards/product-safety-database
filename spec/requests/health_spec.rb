require "rails_helper"

RSpec.describe "Health Check", :with_opensearch, :with_stubbed_mailer, :with_2fa do
  describe "/health/all" do
    let(:sidekiq_latency) { 29 }
    let(:sidekiq_queue) { instance_double(Sidekiq::Queue, latency: sidekiq_latency) }
    let(:auth_headers) { { "Authorization" => "Basic #{Base64.encode64('health:check')}" } }

    before do
      create(:allegation)
      Investigation.reindex
      allow(Sidekiq::Queue).to receive(:new).with("psd").and_return(sidekiq_queue)
    end

    it "checks health" do
      get health_all_path, headers: auth_headers
      expect(response).to be_successful
    end

    context "when sidekiq is not responsive" do
      let(:sidekiq_latency) { 31 }

      it do
        expect { get health_all_path, headers: auth_headers }.to raise_error(RuntimeError, "Sidekiq queue latency is above 30 seconds")
      end
    end
  end
end
