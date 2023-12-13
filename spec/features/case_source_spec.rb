require "rails_helper"

RSpec.feature "Case source info", :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }

  before do
    sign_in user
    visit investigation_path(investigation)
  end

  context "when investigation has no source info" do
    let(:investigation) { create(:allegation, creator: user) }

    it "does not show the source info on the page" do
      expect(page).not_to have_link "Notification source"
      expect(page).not_to have_css("h3", text: "Notification source")
    end
  end

  context "when investigation has source info" do
    let(:complainant) { create(:complainant) }

    context "when user is not opss" do
      context "when the user's team is added to the notification" do
        let(:investigation) { create(:allegation, complainant:, creator: user) }

        it "shows the source info on the page" do
          expect(page).to have_link "Notification source"
          expect(page).to have_css("h3", text: "Notification source")
          expect(page).to have_content(complainant.name)
          expect(page).to have_content(complainant.complainant_type)
          expect(page).not_to have_content("Only teams added to the notification can view enquiry contact details")
        end
      end

      context "when the user's team is not owner of the notification" do
        let(:other_team) { create(:team) }
        let(:other_user) { create(:user, :activated, has_viewed_introduction: true, team: other_team) }
        let(:investigation) { create(:allegation, complainant:, creator: other_user) }

        it "does not show source info on the page" do
          expect(page).to have_link "Notification source"
          expect(page).to have_css("h3", text: "Notification source")
          expect(page).not_to have_content(complainant.name)
          expect(page).to have_content(complainant.complainant_type)
          expect(page).to have_content("Only teams added to the notification can view allegation contact details")
        end
      end
    end

    context "when the user is opss" do
      let(:investigation) { create(:allegation, complainant:, creator: user) }

      it "shows the source info on the page" do
        expect(page).to have_link "Notification source"
        expect(page).to have_css("h3", text: "Notification source")
        expect(page).to have_content(complainant.name)
        expect(page).to have_content(complainant.complainant_type)
        expect(page).not_to have_content("Only teams added to the notification can view enquiry contact details")
      end
    end
  end
end
