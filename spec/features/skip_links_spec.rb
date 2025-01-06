require "rails_helper"

RSpec.feature "Skip links", :with_opensearch, type: :feature do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }

  before do
    sign_in user
  end

  scenario "only one skip link exists on the homepage" do
    visit "/"
    expect(page).to have_css(".govuk-skip-link", count: 1)
    expect(page).to have_link("Skip to main content", href: "#main-content")
  end

  scenario "only one skip link exists on the products page" do
    visit "/products"
    expect(page).to have_css(".govuk-skip-link", count: 1)
    expect(page).to have_link("Skip to main content", href: "#main-content")
  end

  scenario "skip link appears at the start of the page" do
    visit "/"
    expect(page).to have_css("body > a.govuk-skip-link:first-child")
  end

  scenario "skip link points to main content section" do
    visit "/"
    expect(page).to have_css("main#main-content")
  end
end
