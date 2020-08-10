require "rails_helper"

RSpec.feature "Business listing", :with_elasticsearch, :with_stubbed_mailer, type: :feature do
  let(:user)            { create :user, :activated, has_viewed_introduction: true }
  let!(:business_one)   { create(:business, trading_name: "great value",    created_at: 1.day.ago) }
  let!(:business_two)   { create(:business, trading_name: "mediocre stuff", created_at: 2.days.ago) }
  let!(:business_three) { create(:business, trading_name: "pretty bad",     created_at: 3.days.ago) }

  before do
    create_list :business, 18, created_at: 4.days.ago
    sign_in(user)
  end

  scenario "lists products according to search relevance" do
    Business.import refresh: :wait_for
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

  scenario "displays cases for product" do
    investigation = create(:allegation, :with_business, business_to_add: business_one)
    visit "/businesses/#{business_one.id}"
    save_page
    within ".psd-case-card" do
      expect(page).to have_link(investigation.title, href: "/cases/#{investigation.pretty_id}")
    end
    investigation.update(is_private: true)
    visit "/businesses/#{business_one.id}"
    within ".psd-case-card" do
      expect(page).to have_css("span", text: "Allegation restricted")
    end
  end
end
