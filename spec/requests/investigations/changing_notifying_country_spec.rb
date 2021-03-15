require "rails_helper"

RSpec.describe "Changing notifying country of a case", :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_notify, type: :request do
  let(:user) { create(:user, :activated) }

  let(:investigation) do
    create(
      :allegation,
      is_closed: false,
      creator: user
    )
  end

  context "when the user has notifying_country_editor role" do
    before do
      user.roles.create!(name: "notifying_country_editor")
      sign_in user
      put investigation_notifying_country_path(investigation),
          params: {
            investigation: {
              country: "country:GB-ENG",
            }
          }
    end

    it "redirects to the confirm page" do
      expect(response).to redirect_to(investigation_path(investigation))
    end
  end

  context "when the user does not have notifying_country_editor role" do
    before do
      sign_in user
      put investigation_notifying_country_path(investigation),
          params: {
              investigation: {
                country: "country:GB-ENG",
              }
          }
    end

    it "returns a forbidden status code" do
      byebug
      expect(response).to have_http_status(:forbidden)
    end
  end
end
