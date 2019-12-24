require "rails_helper"

RSpec.feature "Investigation listing", :with_elasticsearch, :with_stubbed_mailer, :with_stubbed_keycloak_config do
  let(:user) { create :user, :activated }
  let!(:investigation_last_updated_3_days_ago) { create(:investigation, updated_at: 3.days, description: "3 days old").decorate }
  let!(:investigation_last_updated_2_days_ago) { create(:investigation, updated_at: 2.days, description: "2 days old").decorate }
  let!(:investigation_last_updated_1_days_ago) { create(:investigation, updated_at: 1.day, description: "1 days old").decorate }

  scenario "lists cases correctly sorted" do
    Investigation.import refresh: :wait_for
    sign_in(as_user: user)
    visit investigations_path

    expect(page).
      to have_css(".govuk-grid-row.psd-case-card:nth-child(1) .govuk-grid-column-one-half span.govuk-caption-m", text: investigation_last_updated_1_days_ago.pretty_description)
    expect(page).
      to have_css(".govuk-grid-row.psd-case-card:nth-child(2) .govuk-grid-column-one-half span.govuk-caption-m", text: investigation_last_updated_2_days_ago.pretty_description)
    expect(page).
      to have_css(".govuk-grid-row.psd-case-card:nth-child(3) .govuk-grid-column-one-half span.govuk-caption-m", text: investigation_last_updated_3_days_ago.pretty_description)

    fill_in "Keywords", with: investigation_last_updated_3_days_ago.object.description
    choose "Relevance"
    click_on "Apply filters"

    expect(page).
      to have_css(".govuk-grid-row.psd-case-card:nth-child(1) .govuk-grid-column-one-half span.govuk-caption-m", text: investigation_last_updated_3_days_ago.pretty_description)
  end
end
