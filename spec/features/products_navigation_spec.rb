require "rails_helper"

RSpec.feature "Searching products", :with_stubbed_mailer, type: :feature do
  let(:team) { create :team }
  let(:user) { create :user, :activated, has_viewed_introduction: true, team: }

  let(:other_user_same_team) { create :user, :activated, has_viewed_introduction: true, team: }
  let!(:user_product) { create(:product) }
  let!(:other_product) { create(:product) }
  let!(:team_product) { create(:product) }
  let!(:closed_product) { create(:product) }

  def create_four_products!
    create(:notification, creator: user, products: [user_product])
    create(:notification, products: [other_product])
    create(:notification, creator: other_user_same_team, products: [team_product])
    create(:notification, creator: user, products: [closed_product], is_closed: true)
    Investigation.reindex
  end

  scenario "No products" do
    sign_in user
    visit "/products"

    click_on "Your products"

    expect(highlighted_tab).to eq "Your products"
    expect(page).to have_content "There are 0 product records included in open notifications where you are the notification owner."

    click_on "Team products"

    expect(highlighted_tab).to eq "Team products"
    expect(page).to have_content "There are 0 product records included in open notifications where the #{team.name} team is the notification owner."
  end

  scenario "Browsing products" do
    create_four_products!

    sign_in user
    visit "/products"

    expect(highlighted_tab).to eq "All products - Search"
    expect(page).to have_selector("td.govuk-table__cell", text: user_product.psd_ref)
    expect(page).to have_selector("td.govuk-table__cell", text: other_product.psd_ref)
    expect(page).to have_selector("td.govuk-table__cell", text: team_product.psd_ref)
    expect(page).to have_selector("td.govuk-table__cell", text: closed_product.psd_ref)
    expect(page).not_to have_css("form dl.opss-dl-select dd") # sort filter drop down

    click_on "Your products"

    expect(highlighted_tab).to eq "Your products"
    expect(page).to have_selector("td.govuk-table__cell", text: user_product.psd_ref)
    expect(page).not_to have_selector("td.govuk-table__cell", text: other_product.psd_ref)
    expect(page).not_to have_selector("td.govuk-table__cell", text: team_product.psd_ref)
    expect(page).not_to have_selector("td.govuk-table__cell", text: closed_product.psd_ref)
    expect(page).not_to have_css("form dl.opss-dl-select dd") # sort filter drop down

    click_on "Team products"

    expect(highlighted_tab).to eq "Team products"
    expect(page).to have_selector("td.govuk-table__cell", text: user_product.psd_ref)
    expect(page).to have_selector("td.govuk-table__cell", text: team_product.psd_ref)
    expect(page).not_to have_selector("td.govuk-table__cell", text: other_product.psd_ref)
    expect(page).not_to have_selector("td.govuk-table__cell", text: closed_product.psd_ref)
    expect(page).not_to have_css("form dl.opss-dl-select dd") # sort filter drop down

    # Add more products and reload page
    10.times { create(:notification, creator: other_user_same_team, products: [create(:product)]) }

    visit "/products"

    expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Newly added") # sort filter drop down
  end

  def highlighted_tab
    find(".opss-left-nav__active").text
  end
end
