require "rails_helper"

RSpec.feature "Product owner contact details", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated) }
  let(:product) { create(:product, subcategory: "Lamp", owning_team: nil) }
  let(:first_owning_team) { create(:team, team_recipient_email: "team@example.com") }
  let(:creation_time) { 3.weeks.ago }
  let(:first_owned_time) { 2.weeks.ago }
  let(:first_unowned_time) { 1.week.ago }

  before do
    travel_to creation_time { product }
    travel_to first_owned_time { product.update owning_team: first_owning_team }
    travel_to first_unowned_time { product.update owning_team: nil }
    sign_in user
  end

  scenario "viewing versioned product owner details" do
    visit "/products/#{product.id}/owner"

    # The product is currently unowned, so we expect a 404
    expect(page).to have_http_status(:not_found)
    expect(page).to have_text("Page not found")

    # Edit the product to gain ownership
    visit "/products/#{product.id}/edit"
    fill_in "Product subcategory", with: "Candle"
    click_button "Save"
    expect(page).to have_summary_item(key: "Product subcategory", value: "Candle")

    # The product is now owned by our team, so we expect our team's details
    visit "/products/#{product.id}/owner"
    expect(page).to have_http_status(:ok)
    expect(page).to have_summary_item(key: "Product record", value: "psd-#{product.id}")
    expect(page).to have_summary_item(key: "Record owner", value: user.team.name)
    expect(page).to have_summary_item(key: "Organisation", value: user.team.organisation.name)

    # The original version has no owner, so visiting the versioned record should produce a 404
    visit "/products/#{product.id}/#{creation_time.to_i}/owner"
    expect(page).to have_http_status(:not_found)
    expect(page).to have_text("Page not found")

    # The the second version has another team as owner, so expect their details
    visit "/products/#{product.id}/#{first_owned_time.to_i}/owner"
    expect(page).to have_http_status(:ok)
    expect(page).to have_summary_item(key: "Product record", value: "psd-#{product.id}_#{first_owned_time.to_i}")
    expect(page).to have_summary_item(key: "Record owner", value: first_owning_team.name)
    expect(page).to have_summary_item(key: "Organisation", value: first_owning_team.organisation.name)
    expect(page).to have_summary_item(key: "Contact details", value: "Email: #{first_owning_team.team_recipient_email}")

    # The third version has no owner, so visiting the versioned record should produce a 404
    visit "/products/#{product.id}/#{first_unowned_time.to_i}/owner"
    expect(page).to have_http_status(:not_found)
    expect(page).to have_text("Page not found")
  end
end
