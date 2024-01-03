require "rails_helper"

RSpec.feature "Your businesses listing", :with_stubbed_mailer, type: :feature do
  let(:organisation) { create(:organisation) }
  let(:user) { create(:user, :activated, organisation:, has_viewed_introduction: true) }

  let!(:business_one) { create(:business, trading_name: "great value", created_at: 1.day.ago) }
  let!(:business_two) { create(:business, trading_name: "mediocre stuff", created_at: 2.days.ago) }
  let!(:business_three) { create(:business, trading_name: "pretty bad", created_at: 3.days.ago) }

  before do
    create(:notification, :with_business, hazard_type: "Chemical", business_to_add: business_one, creator: user)
    create(:notification, :with_business, hazard_type: "Fire", business_to_add: business_two, creator: user)
    create(:notification, :with_business, hazard_type: "Drowning", business_to_add: business_three, creator: user)

    create_list :business, 18, created_at: 4.days.ago
    sign_in(user)
    visit your_businesses_path
  end

  scenario "it shows all recently added businesses that have a notification opened by me" do
    expect(page).to have_css("table tbody.govuk-table__body > tr:nth-child(1) > th:nth-child(1)", text: business_one.trading_name)
    expect(page).to have_css("table tbody.govuk-table__body > tr:nth-child(2) > th:nth-child(1)", text: business_two.trading_name)
    expect(page).to have_css("table tbody.govuk-table__body > tr:nth-child(3) > th:nth-child(1)", text: business_three.trading_name)
  end

  context "when I open a notification linked to an approved online marketplace" do
    let(:online_marketplace) { create(:online_marketplace, :approved) }
    let!(:business_four) { create(:business, trading_name: "Exploding Things Ltd", online_marketplace:) }
    let!(:notification) { create(:notification, hazard_type: "Explosion", creator: user) }

    before do
      AddBusinessToNotification.call!(
        business: business_four,
        relationship: "online_marketplace",
        online_marketplace:,
        notification:,
        user:
      )
      visit your_businesses_path
    end

    scenario "it doesn't show the online marketplace business in 'My businesses'" do
      expect(page).not_to have_text(business_four.trading_name)
    end
  end
end
