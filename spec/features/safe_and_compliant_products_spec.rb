require "rails_helper"

RSpec.feature "Viewing safe and compliant products", :with_stubbed_mailer, :with_stubbed_opensearch do
  let(:user)          { create(:user, :opss_user, :activated) }
  let(:investigation) { create(:enquiry, :with_products, creator: user) }

  before do
    sign_in user
    visit "/cases/#{investigation.pretty_id}"
  end

  scenario "No safety and compliance information" do
    within "nav[aria-label='Secondary']" do
      click_link "Products"
    end

    expect(page).not_to have_text("This notification has reported any included products as safe and compliant.")
  end

  scenario "Recording the notification products as safe and compliant" do
    click_link "Edit the safety and compliance"

    choose "As safe and compliant"

    click_button "Continue"

    expect(page).to have_text("Product reported as safe and compliant")

    within "nav[aria-label='Secondary']" do
      click_link "Products"
    end

    expect(page).to have_text("This notification has reported any included products as safe and compliant.")
  end
end
