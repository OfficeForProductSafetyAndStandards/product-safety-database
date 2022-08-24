require "rails_helper"

RSpec.describe "Market Surveillance Authority case creation wizard", :with_stubbed_opensearch, type: :request do
  let(:user) { create(:user, :activated) }

  before { sign_in(user) }

  context "when requesting a later step before having started the wizard" do
    before { get "/ts_investigation/reference_number" }

    it "responds with a 302 status code" do
      expect(response).to redirect_to(new_ts_investigation_path)
    end
  end
end
