require "rails_helper"

RSpec.describe "Healthcheck", :with_elasticsearch, :with_stubbed_mailer, :with_2fa do
  describe "/health/all" do
    before do
      create(:allegation)
    end

    it "checks health" do
      auth_headers = {"Authorization" => "Basic #{Base64.encode64('health:check')}"}
      get health_all_path, headers: auth_headers
      expect(response).to be_success
    end
  end
end
