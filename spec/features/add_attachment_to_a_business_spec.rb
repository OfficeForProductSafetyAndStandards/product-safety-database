require "rails_helper"

RSpec.feature "Add an attachment to a business", :with_stubbed_opensearch, :with_stubbed_antivirus, type: :feature do
  let(:user)     { create(:user, :activated, has_viewed_introduction: true) }
  let(:business) { create(:business) }

  let(:file)        { Rails.root.join "test/fixtures/files/testImage.png" }
  let(:title)       { Faker::Lorem.sentence }
  let(:description) { Faker::Lorem.paragraph }

  scenario "Adding an attachment" do
    sign_in user
    visit "/businesses/#{business.id}"

    expect_to_be_on_business_page(business_id: business.id, business_name: business.trading_name)

    click_link "Add attachment"
    expect_to_be_on_add_attachment_to_a_business_page(business_id: business.id)

    click_button "Save attachment"

    expect(page).to have_error_summary("Select a file", "Enter a document title")

    attach_file "document[document]", file
    fill_in "Document title", with: title
    fill_in "Description",    with: description

    click_button "Save attachment"

    expect_to_be_on_business_page(business_id: business.id, business_name: business.trading_name)
    expect_confirmation_banner("The image was added")

    expect(page).to have_selector("h2", text: title)
    expect(page).to have_selector("p", text: description)
  end
end
