require "rails_helper"

RSpec.describe "Table accessibility" do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:notification, creator: user) }
  let(:mail_message) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

  before do
    allow(NotifyMailer).to receive(:notification_created).and_return(mail_message)
    investigation # Create the investigation
    sign_in(user)
  end

  describe "notifications tables" do
    it "has proper accessibility attributes" do
      visit "/notifications/your-notifications"

      # Check table class
      expect(page).to have_css("table.govuk-table")

      # Check header cells have scope
      within "table" do
        expect(page).to have_css("th[scope='col']")
      end

      # Check hidden descriptions
      expect(page).to have_css("caption.govuk-visually-hidden", text: "Notifications data: 5 columns with each notification described across rows within each table body.", visible: :all)

      # Check links have aria-describedby
      expect(page).to have_css("a[aria-describedby]")
    end

    it "has proper row indices" do
      visit "/notifications/team-notifications"

      within "tbody" do
        expect(page).to have_css("tr[aria-rowindex='1']")
        expect(page).to have_css("tr[aria-rowindex='2']")
        expect(page).to have_css("tr[aria-rowindex='3']")
      end
    end
  end
end
