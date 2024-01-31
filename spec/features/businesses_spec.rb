require "rails_helper"

RSpec.feature "Business listing", :with_stubbed_mailer, type: :feature do
  let(:user)            { create :user, :activated, has_viewed_introduction: true }
  let!(:business_one)   { create(:business, :online_marketplace, trading_name: "great value", created_at: 1.day.ago) }
  let!(:business_two)   { create(:business, :retailer, trading_name: "mediocre stuff", created_at: 2.days.ago) }
  let!(:business_three) { create(:business, :manufacturer, trading_name: "pretty bad", created_at: 3.days.ago) }

  before do
    create_list :business, 18, created_at: 4.days.ago
    business_one
    business_two
    business_three
    sign_in(user)
    visit all_businesses_path
  end

  context "when no keywords are entered" do
    it "shows total number of businesses" do
      expect(page).to have_content "There are currently #{Business.without_online_marketplaces.count} businesses."
    end
  end

  scenario "lists business according to search relevance" do
    within "table tbody.govuk-table__body > tr:nth-child(1) > th:nth-child(1)" do
      expect(page).to have_link(business_one.trading_name, href: business_path(business_one))
    end

    within "table tbody.govuk-table__body > tr:nth-child(2) > th:nth-child(1)" do
      expect(page).to have_link(business_two.trading_name, href: business_path(business_two))
    end

    within "table tbody.govuk-table__body > tr:nth-child(3) > th:nth-child(1)" do
      expect(page).to have_link(business_three.trading_name, href: business_path(business_three))
    end

    expect(page).to have_css(".govuk-pagination__link", text: "1")
    expect(page).to have_link("Next", href: all_businesses_path(page: 2))

    fill_in "Search", with: business_three.trading_name
    click_on "Submit search"

    within "table tbody.govuk-table__body > tr:nth-child(1) > th:nth-child(1)" do
      expect(page).to have_link(business_three.trading_name, href: business_path(business_three))
    end
  end

  scenario "strips leading and trailing whitespace from search queries" do
    fill_in "Search", with: "  #{business_three.trading_name} "
    click_on "Submit search"

    within "table tbody.govuk-table__body > tr:nth-child(1) > th:nth-child(1)" do
      expect(page).to have_link(business_three.trading_name, href: business_path(business_three))
    end
  end

  scenario "displays cases for business" do
    investigation = business_one.investigations.first
    visit "/businesses/#{business_one.id}"

    within ".psd-case-card" do
      expect(page).to have_link(investigation.title, href: "/cases/#{investigation.pretty_id}")
    end
    investigation.update!(is_private: true)
    visit "/businesses/#{business_one.id}"
    within ".psd-case-card" do
      expect(page).to have_css("span", text: "Notification restricted")
    end
  end

  scenario "search by business type" do
    visit all_businesses_path
    find("details#business-type").click
    check "Online marketplace"
    check "Retailer"
    check "Manufacturer"
    click_button "Apply"

    expect(page).to have_link(business_one.trading_name, href: business_path(business_one))
    expect(page).to have_link(business_two.trading_name, href: business_path(business_two))
    expect(page).to have_link(business_three.trading_name, href: business_path(business_three))

    find("details#business-type").click
    uncheck "Online marketplace"
    click_button "Apply"

    expect(page).not_to have_link(business_one.trading_name, href: business_path(business_one))
    expect(page).to have_link(business_two.trading_name, href: business_path(business_two))
    expect(page).to have_link(business_three.trading_name, href: business_path(business_three))

    find("details#business-type").click
    uncheck "Retailer"
    click_button "Apply"

    expect(page).not_to have_link(business_one.trading_name, href: business_path(business_one))
    expect(page).not_to have_link(business_two.trading_name, href: business_path(business_two))
    expect(page).to have_link(business_three.trading_name, href: business_path(business_three))

    find("details#business-type").click
    uncheck "Manufacturer"
    click_button "Apply"

    expect(page).to have_link(business_one.trading_name, href: business_path(business_one))
    expect(page).to have_link(business_two.trading_name, href: business_path(business_two))
    expect(page).to have_link(business_three.trading_name, href: business_path(business_three))
  end
end
