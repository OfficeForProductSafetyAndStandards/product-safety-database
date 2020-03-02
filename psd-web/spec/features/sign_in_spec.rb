require "rails_helper"

RSpec.describe "Signing in", :with_stubbed_mailer, :with_stubbed_keycloak_config, :with_elasticsearch, type: :feature do
  include ActiveSupport::Testing::TimeHelpers
  let(:investigation) { create(:project) }
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:groups) { user.teams.flat_map(&:path) << user.organisation.path }

  before do
    OmniAuth.config.mock_auth[:openid_connect] = {
      "provider" => :openid_connect,
      "uid"  => user.id,
      "info" => {
        "email" => user.email,
        "name" => user.name,
      },
      "extra" => {
        "raw_info" => {
          "groups" => groups
        }
      }
    }
  end

  it "allows to sign in and times you out in due time" do
    visit investigation_path(investigation)
    expect(page).not_to have_css("h2#error-summary-title", text: "You need to sign in or sign up before continuing.")

    travel_to 24.hours.from_now do
      visit investigation_path(investigation)
      expect(page).not_to have_css("h2#error-summary-title", text: "Your session expired. Please sign in again to continue.")
    end
  end
end
