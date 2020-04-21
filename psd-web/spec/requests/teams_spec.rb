require "rails_helper"

RSpec.describe "Teams management", :with_stubbed_mailer, :with_stubbed_notify, type: :request do
  let(:team) { create(:team) }
  let(:team_admin) { create(:user, :team_admin, :activated, has_viewed_introduction: true, teams: [team]) }

  describe "#invite_to" do
    context "when the email whitelist is enabled" do
      before do
        allow(Rails.application.config).to receive(:email_whitelist_enabled).and_return(true)
        allow(Rails.application.config).to receive(:secondary_authentication_enabled).and_return(false)

        sign_in(team_admin)
      end

      it "checks whitelisted TLDs insensitively" do
        expect {
          put invite_to_team_url(team), params: { new_user: { email_address: "new_user@NORTHAMPTONSHIRE.gov.uk" } }
        }.to change { team.reload.users.count }.from(1).to(2)
         .and(change(User, :count).from(1).to(2))
      end
    end
  end
end
