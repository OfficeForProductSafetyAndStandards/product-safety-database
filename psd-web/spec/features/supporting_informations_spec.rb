require "rails_helper"

RSpec.feature "Supporting information", :with_stubbed_elasticsearch, :with_stubbed_mailer do
  let(:investigation) { create(:allegation, :with_antivirus_checked_document).decorate }

  before { sign_in create(:user, :activated, has_viewed_introduction: true) }

  scenario "listing supporting information" do
    visit "/cases/#{investigation.pretty_id}"

    click_on "Supporting information (1)"

    within "table.govuk-table tbody.govuk-table__body" do
      investigation.activities.each do |activity|
        expect(page).to have_css("tr.govuk-table__row td.govuk-table__cell", text: activity.title)
      end
    end

    within
  end
end
