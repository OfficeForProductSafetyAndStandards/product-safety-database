require "rails_helper"

RSpec.feature "Case actions", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:user) { create :user, :activated, has_viewed_introduction: true }
  let(:investigation_1) { create :allegation, creator: user }
  let(:washing_machine) { create :product_washing_machine, created_at: 1.day.ago }
  let(:investigation_2) { create :allegation, products: [washing_machine], hazard_type: "Cuts", creator: user }

  before do
    sign_in user
  end

  scenario "without a product added to the case" do
    visit investigation_path(investigation_1)
    expect_to_be_on_case_page(case_id: investigation_1.pretty_id)
    expect(page).to have_css(".govuk-warning-text")
    expect(page).to have_text("A product has not been added to this case.")
  end

  scenario "with a product added to the case" do
    visit investigation_path(investigation_2)
    expect_to_be_on_case_page(case_id: investigation_2.pretty_id)
    expect(page).not_to have_css(".govuk-warning-text")
  end
end
