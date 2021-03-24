require "rails_helper"

RSpec.describe "Sending a product safety alert", :with_stubbed_elasticsearch, :with_stubbed_mailer, type: :request do
  let(:user) { create(:user, :activated, :email_alert_sender) }

  before { sign_in user }

  context "when the case is not restricted" do
    let(:investigation) { create(:allegation, creator: user) }

    it "responds with a 200 status code" do
      get investigation_alert_url(investigation, id: "compose")
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the case is restricted" do
    let(:investigation) { create(:allegation, :restricted, creator: user) }

    it "raises a Pundit::NotAuthorizedError exception" do
      expect { get investigation_alert_url(investigation, id: "compose") }.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
