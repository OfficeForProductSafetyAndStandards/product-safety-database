require "rails_helper"

RSpec.feature "Product owner contact details", :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated) }
  let(:product) { create(:product, subcategory: "Lamp", owning_team_id: nil) }
  let(:first_investigation) { create(:allegation, creator: user) }
  let(:second_investigation) { create(:allegation, creator: user) }
  let(:third_investigation) { create(:allegation, creator: user) }
  let(:first_owning_team) { create(:team, team_recipient_email: "team@example.com") }

  before do
    product.update! owning_team: first_owning_team
    AddProductToCase.call!(product:, investigation: first_investigation, user:)
    ChangeCaseStatus.call!(investigation: first_investigation, new_status: "closed", user:)
    product.update! owning_team: nil
    sign_in user
  end

  scenario "viewing versioned product owner details" do
    visit "/products/#{product.id}/owner"

    # The product is currently unowned, so we expect a 404
    expect(page).to have_http_status(:not_found)
    expect(page).to have_text("Page not found")

    # Link the product to a new open case to gain ownership
    visit "/cases/#{third_investigation.pretty_id}/products/new"
    fill_in "reference", with: product.id
    click_button "Continue"
    choose "Yes"
    click_button "Save and continue"

    # The product is now owned by our team, so we expect our team's details
    visit "/products/#{product.id}/owner"
    expect(page).to have_http_status(:ok)
    expect(page).to have_summary_item(key: "Product record", value: "psd-#{product.id}")
    expect(page).to have_summary_item(key: "Record owner", value: user.team.name)
    expect(page).to have_summary_item(key: "Organisation", value: user.team.organisation.name)

    # The version linked to the case has the first_owning_team as an owner at the time
    # the case was closed
    investigation_product_id = first_investigation.investigation_products.find_by(product:).id
    visit "/cases/#{first_investigation.pretty_id}/investigation_products/#{investigation_product_id}/owner"
    expect(page).to have_http_status(:ok)
    expect(page).to have_summary_item(key: "Product record", value: "psd-#{product.id}_#{first_investigation.date_closed.to_i}")
    expect(page).to have_summary_item(key: "Record owner", value: first_owning_team.team.name)
    expect(page).to have_summary_item(key: "Organisation", value: first_owning_team.team.organisation.name)

    # Adding the live product to a case will show the live owner (our team)
    AddProductToCase.call!(product: product.reload, investigation: second_investigation, user:)

    investigation_product_id = second_investigation.investigation_products.find_by(product:).id
    visit "/cases/#{second_investigation.pretty_id}/investigation_products/#{investigation_product_id}/owner"
    expect(page).to have_http_status(:ok)
    expect(page).to have_summary_item(key: "Product record", value: "psd-#{product.id}")
    expect(page).to have_summary_item(key: "Record owner", value: user.team.name)
    expect(page).to have_summary_item(key: "Organisation", value: user.team.organisation.name)
  end
end
