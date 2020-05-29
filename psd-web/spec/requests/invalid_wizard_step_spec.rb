require "rails_helper"

RSpec.describe "Invalid steps within wizards", :with_stubbed_elasticsearch, :with_stubbed_notify, :with_stubbed_mailer, type: :request do
  let(:user) { create(:user, :opss_user, :activated) }
  let(:investigation) { create(:allegation, owner: user.team) }

  before { sign_in(user) }

  context "when requesting an invalid step" do
    before do
      get "/cases/#{investigation.pretty_id}/corrective_actions/invalid-step"
    end

    it "renders 'Page not found'" do
      expect(response).to render_template("errors/not_found")
    end

    it "renders with a 404 status code" do
      expect(response).to have_http_status(404)
    end
  end
end
