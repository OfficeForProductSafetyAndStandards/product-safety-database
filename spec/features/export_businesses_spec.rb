require "rails_helper"

RSpec.feature "Exporting businesses", :with_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated, :psd_admin, has_viewed_introduction: true) }
  let!(:investigation) { create(:allegation, :with_business) }
  let(:business_1) { investigation.businesses.first }
  let!(:business_2) { create(:business, trading_name: "ACME Ltd").decorate }
  let!(:business_3) { create(:business, trading_name: "OPSS").decorate }

  before { Business.import(force: true) }

  scenario "all businesses" do
    sign_in user
    visit "/businesses"

    click_link "Export as spreadsheet"

    expect(page.body).to eq("id,company_number,created_at,legal_name,trading_name,updated_at,types\n#{business_3.id},#{business_3.company_number},#{business_3.created_at},#{business_3.legal_name},#{business_3.trading_name},#{business_3.updated_at},#{business_3.types}\n#{business_2.id},#{business_2.company_number},#{business_2.created_at},#{business_2.legal_name},#{business_2.trading_name},#{business_2.updated_at},#{business_2.types}\n#{business_1.id},#{business_1.company_number},#{business_1.created_at},#{business_1.legal_name},#{business_1.trading_name},#{business_1.updated_at},\"[\"\"Manufacturer\"\"]\"\n")
  end

  scenario "searching businesses" do
    sign_in user
    visit "/businesses"

    fill_in "Keywords", with: "OPSS"
    click_button "Search"

    click_link "Export as spreadsheet"

    expect(page.body).to eq("id,company_number,created_at,legal_name,trading_name,updated_at,types\n#{business_3.id},#{business_3.company_number},#{business_3.created_at},#{business_3.legal_name},#{business_3.trading_name},#{business_3.updated_at},#{business_3.types}\n")
  end
end
