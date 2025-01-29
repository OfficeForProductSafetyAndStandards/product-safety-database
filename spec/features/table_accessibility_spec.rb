require "rails_helper"

RSpec.describe "Table accessibility" do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:notification, creator: user) }
  let(:mail_message) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

  before do
    allow(NotifyMailer).to receive(:notification_created).and_return(mail_message)
    investigation
    sign_in(user)
  end

  describe "notifications tables" do
    context "when viewing notification tables" do
      it "implements WCAG 2.1 table structure requirements" do
        visit "/notifications/your-notifications"

        expect(page).to have_css("table.govuk-table")

        within "table" do
          expect(page).to have_css("th[scope='col']")
        end

        expect(page).to have_css(
          "caption.govuk-visually-hidden",
          text: "Notifications data: 5 columns with each notification described across rows within each table body.",
          visible: :all
        )

        expect(page).to have_css("a[aria-describedby]")
      end

      it "implements proper row hierarchy for screen readers" do
        visit "/notifications/team-notifications"

        within "tbody" do
          expect(page).to have_css("tr[aria-rowindex='1']")
          expect(page).to have_css("tr[aria-rowindex='2']")
          expect(page).to have_css("tr[aria-rowindex='3']")
        end
      end
    end
  end
end
