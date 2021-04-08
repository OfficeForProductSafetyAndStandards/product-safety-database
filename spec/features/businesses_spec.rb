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

  scenario "lists business according to search relevance" do
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

  scenario "displays cases for business" do
    investigation = create(:allegation, :with_business, business_to_add: business_one)
    visit "/businesses/#{business_one.id}"
    save_page
    within ".psd-case-card" do
      expect(page).to have_link(investigation.title, href: "/cases/#{investigation.pretty_id}")
    end
    investigation.update!(is_private: true)
    visit "/businesses/#{business_one.id}"
    within ".psd-case-card" do
      expect(page).to have_css("span", text: "Allegation restricted")
    end
  end

  scenario "delete a business" do
    investigation = create(:allegation, :with_business, business_to_add: business_one, creator: user)

    visit "/cases/#{investigation.pretty_id}/businesses"

    expect(page).to have_summary_item(key: "Trading name",             value: business_one.trading_name)
    expect(page).to have_summary_item(key: "Registered or legal name", value: business_one.legal_name)
    expect(page).to have_summary_item(key: "Company number",           value: business_one.company_number)
    expect(page).to have_summary_item(key: "Address",                  value: business_one.primary_location&.summary)
    expect(page).to have_summary_item(key: "Contact",                  value: business_one.primary_contact&.summary)

    click_on "Remove business"

    expect(page).to have_css("p.govuk-body", text: "Remove a business from a case if it's not relevant to the investigation. Business details can be changed from the Businesses tab.")

    expect(page).to have_unchecked_field("No")
    expect(page).to have_unchecked_field("Yes")

    click_on "Remove business"

    expect(page).to have_error_messages
    expect(page).to have_error_summary "Select yes if you want to remove the business from the case"

    within_fieldset("Do you wamt to remove the business from the case?") do
      choose "Yes"
      fill_in "Reason for removing the business from the case", with: "This business no longer exists"
    end
    save_and_open_page

    click_on "Remove business"

    expect(page).to have_css(".hmcts-banner__message", text: "Business was successfully removed.")
    expect(page).to have_css("p.govuk-body", text: "No businesses")
  end
end
