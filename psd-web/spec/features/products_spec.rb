require "rails_helper"

RSpec.describe "Busisnesses listing", :with_elasticsearch, :with_stubbed_mailer, :with_stubbed_keycloak_config  do
  let(:user) { create :user, :activated }

  before { create_list :product, 21, created_at: 4.days.ago }

  scenario "lists products according to search relevance" do
    sign_in(as_user: user)
    visit products_path

    expect(page).to have_css(".pagination em.current", text: 1)
    expect(page).to have_link("2", href: products_path(page: 2))
    expect(page).to have_link("Next →", href: products_path(page: 2))
  end
end
