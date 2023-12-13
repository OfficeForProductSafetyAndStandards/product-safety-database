require "rails_helper"

RSpec.feature "Business listing", :with_stubbed_mailer, type: :feature do
  let(:user)            { create :user, :activated, has_viewed_introduction: true }
  let!(:business_one)   { create(:business, trading_name: "great value",    created_at: 1.day.ago) }
  let!(:business_two)   { create(:business, trading_name: "mediocre stuff", created_at: 2.days.ago) }
  let!(:business_three) { create(:business, trading_name: "pretty bad",     created_at: 3.days.ago) }

  before do
    create_list :business, 18, created_at: 4.days.ago
    sign_in(user)
    visit businesses_path
  end

  context "when no keywords are entered" do
    it "shows total number of businesses" do
      expect(page).to have_content "There are currently #{Business.count} businesses."
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

    expect(page).to have_css("nav.opss-pagination-link .opss-pagination-link--text", text: "Page 1")
    expect(page).to have_link("Next page", href: all_businesses_path(page: 2))

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
    investigation = create(:allegation, :with_business, business_to_add: business_one)
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

  context "when over 10k cases exist" do
    before do
      allow(Business).to receive(:count).and_return(10_001)
    end

    it "shows total number of cases" do
      visit businesses_path
      expect(page).to have_content "There are currently 10001 businesses."
    end
  end
end
