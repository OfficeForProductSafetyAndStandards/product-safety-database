require "rails_helper"

RSpec.feature "Business listing", :with_elasticsearch, :with_stubbed_mailer, :with_stubbed_keycloak_config do
  let(:user)            { create :user, :activated }
  let!(:business_one)   { create(:business, created_at: 1.day.ago) }
  let!(:business_two)   { create(:business, created_at: 2.days.ago) }
  let!(:business_three) { create(:business, created_at: 3.days.ago) }

  before { create_list :business, 18, created_at: 4.days.ago }

  scenario "lists products according to search relevance" do
    Business.import(refresh: :wait_for)
    sign_in(as_user: user)
    visit businesses_path

    within ".govuk-grid-row.psd-case-card:nth-child(1) > .govuk-grid-column-one-half:nth-child(1) span:nth-child(2)" do
      expect(page).to have_link(business_one.trading_name, href: business_path(business_one))
    end

    within ".govuk-grid-row.psd-case-card:nth-child(2) > .govuk-grid-column-one-half:nth-child(1) span:nth-child(2)" do
      expect(page).to have_link(business_two.trading_name, href: business_path(business_two))
    end

    within ".govuk-grid-row.psd-case-card:nth-child(3) > .govuk-grid-column-one-half:nth-child(1) span:nth-child(2)" do
      expect(page).to have_link(business_three.trading_name, href: business_path(business_three))
    end

    expect(page).to have_css(".pagination em.current", text: 1)
    expect(page).to have_link("2", href: businesses_path(page: 2))
    expect(page).to have_link("Next →", href: businesses_path(page: 2))

    fill_in "Keywords", with: business_three.trading_name
    click_on "Search"

    within ".govuk-grid-row.psd-case-card:nth-child(1) > .govuk-grid-column-one-half:nth-child(1) span:nth-child(2)" do
      expect(page).to have_link(business_three.trading_name, href: business_path(business_three))
    end
  end
end
