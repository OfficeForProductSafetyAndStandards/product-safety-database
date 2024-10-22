require "rails_helper"

RSpec.feature "Business listing", :with_stubbed_mailer, type: :feature do
  let(:user)            { create :user, :opss_user, :activated, has_viewed_introduction: true }
  let(:non_opss_user)            { create :user, :activated, has_viewed_introduction: true }
  let!(:business_one)   { create(:business, :online_marketplace, trading_name: "great value", legal_name: "Great Value Ltd", created_at: 1.day.ago) }
  let!(:business_two)   { create(:business, :retailer, trading_name: "Business name", legal_name: "Business name Ltd", created_at: 2.days.ago) }
  let!(:business_three) { create(:business, :manufacturer, trading_name: "Some Business", legal_name: "Some Business Ltd", created_at: 3.days.ago) }

  before do
    create_list :business, 18, created_at: 4.days.ago
    create(:location, country: "country:GB", business: business_one)
    create(:location, country: "country:FR", business: business_two)
    create(:location, country: "country:AU", business: business_three)
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

    within "table tbody.govuk-table__body > tr:nth-child(1)" do
      expect(page).to have_text(business_one.legal_name)
      expect(page).to have_text(business_one.company_number)
    end

    within "table tbody.govuk-table__body > tr:nth-child(2) > th:nth-child(1)" do
      expect(page).to have_link(business_two.trading_name, href: business_path(business_two))
    end

    within "table tbody.govuk-table__body > tr:nth-child(2)" do
      expect(page).to have_text(business_two.legal_name)
      expect(page).to have_text(business_two.company_number)
    end

    within "table tbody.govuk-table__body > tr:nth-child(3) > th:nth-child(1)" do
      expect(page).to have_link(business_three.trading_name, href: business_path(business_three))
    end

    within "table tbody.govuk-table__body > tr:nth-child(3)" do
      expect(page).to have_text(business_three.legal_name)
      expect(page).to have_text(business_three.company_number)
    end

    expect(page).to have_css(".govuk-pagination__link", text: "1")
    expect(page).to have_link("Next", href: all_businesses_path(page: 2))

    fill_in "Search", with: business_three.trading_name
    click_on "Submit search"

    within "table tbody.govuk-table__body > tr:nth-child(1) > th:nth-child(1)" do
      expect(page).to have_link(business_three.trading_name, href: business_path(business_three))
    end

    within "table tbody.govuk-table__body > tr:nth-child(1)" do
      expect(page).to have_text(business_three.legal_name)
      expect(page).to have_text(business_three.company_number)
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

    expect(investigation).not_to be_nil
    expect(investigation.user_title).not_to be_nil, "Investigation user_title should not be nil for this test"

    visit "/businesses/#{business_one.id}"

    within "#notifications-1" do
      expect(page).to have_text(investigation.user_title)
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

  scenario "search by primary location" do
    visit all_businesses_path
    expect(page).to have_css("h2", text: "Filters")

    find("details#business-location").click
    check "United Kingdom"
    check "France"
    check "Australia"
    click_button "Apply"

    expect(page).to have_link(business_one.trading_name, href: business_path(business_one))
    expect(page).to have_link(business_two.trading_name, href: business_path(business_two))
    expect(page).to have_link(business_three.trading_name, href: business_path(business_three))

    find("details#business-location").click
    uncheck "Australia"
    click_button "Apply"

    expect(page).to have_link(business_one.trading_name, href: business_path(business_one))
    expect(page).to have_link(business_two.trading_name, href: business_path(business_two))
    expect(page).not_to have_link(business_three.trading_name, href: business_path(business_three))

    find("details#business-location").click
    uncheck "France"
    click_button "Apply"

    expect(page).to have_link(business_one.trading_name, href: business_path(business_one))
    expect(page).not_to have_link(business_two.trading_name, href: business_path(business_two))
    expect(page).not_to have_link(business_three.trading_name, href: business_path(business_three))

    find("details#business-location").click
    uncheck "United Kingdom"
    click_button "Apply"

    expect(page).to have_link(business_one.trading_name, href: business_path(business_one))
    expect(page).to have_link(business_two.trading_name, href: business_path(business_two))
    expect(page).to have_link(business_three.trading_name, href: business_path(business_three))
  end

  scenario "non-opss user should not be able to see filters" do
    sign_out
    sign_in(non_opss_user)
    visit all_businesses_path

    expect(page).not_to have_css("h2", text: "Filters")
  end
end
