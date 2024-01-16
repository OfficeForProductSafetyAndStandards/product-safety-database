RSpec.feature "Investigation business page", :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user)                            { create(:user, :activated, has_viewed_introduction: true) }
  let(:other_user)                      { create(:user, :activated, has_viewed_introduction: true) }
  let!(:investigation_without_business) { create(:allegation, creator: user) }
  let!(:investigation_with_business)    { create(:allegation, :with_business, creator: user) }
  let(:business)                        { investigation_with_business.businesses.first }

  context "when user has edit permissions on the case" do
    before do
      sign_in user
    end

    context "when the investigation has no businesses" do
      it "shows no businesses" do
        visit "cases/#{investigation_without_business.pretty_id}/businesses"

        expect(page).to have_content "This notification has not added any businesses."
      end
    end

    context "when investigation has businesses" do
      it "shows business details" do
        visit "cases/#{investigation_with_business.pretty_id}/businesses"
        relationship = InvestigationBusiness.find_by(business_id: business.id, investigation_id: investigation_with_business.id).relationship

        expect(page).to have_css("dt.govuk-summary-list__key", text: "Business type")
        expect(page).to have_css("dd.govuk-summary-list__value", text: relationship)

        expect(page).to have_css("dt.govuk-summary-list__key", text: "Trading name")
        expect(page).to have_css("dd.govuk-summary-list__value", text: business.trading_name)

        expect(page).to have_css("dt.govuk-summary-list__key", text: "Legal name")
        expect(page).to have_css("dd.govuk-summary-list__value", text: business.legal_name)

        expect(page).to have_css("dt.govuk-summary-list__key", text: "Company number")
        expect(page).to have_css("dd.govuk-summary-list__value", text: business.company_number)

        expect(page).to have_link "Edit this business: #{business.trading_name}"
        expect(page).to have_link "Remove this business: #{business.trading_name}"
      end
    end
  end

  context "when user does not have edit permissions on the case" do
    before do
      sign_in other_user
    end

    it "does not show edit or remove links" do
      visit "cases/#{investigation_with_business.pretty_id}/businesses"

      expect(page).not_to have_link "Edit this business: #{business.trading_name}"
      expect(page).not_to have_link "Remove this business: #{business.trading_name}"
    end
  end
end
