require "rails_helper"

RSpec.describe Notifications::CreateHelper, :with_stubbed_mailer do
  describe "notification_link" do
    let(:existing_product) { create(:product) }
    let(:team_with_access) { create(:team, name: "Team with access", team_recipient_email: nil) }
    let(:user) { create(:user, :activated, has_viewed_introduction: true, team: team_with_access) }
    let(:notification)     { create(:notification, creator: user) }
                
    it "outputs notification anchor link" do
        expect(formatted_notification_pretty_id(notification.pretty_id)).to eq("<a class=\"govuk-link\" href=\"/notifications/#{notification.pretty_id}\">#{notification.pretty_id}</a>")
    end

    it "outputs product anchor link" do
        expect(formatted_product(existing_product.id)).to eq("<a class=\"govuk-link\" href=\"/products/#{existing_product.id}\">psd-#{existing_product.id}</a>")
    end
  end
end