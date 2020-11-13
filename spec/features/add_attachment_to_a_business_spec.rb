require "rails_helper"

RSpec.feature "Add an attachment to a business", :with_stubbed_elasticsearch, :with_stubbed_antivirus, type: :feature do
  let(:user)     { create(:user, :activated, has_viewed_introduction: true) }
  let(:business) { create(:business) }

  let(:file)        { Rails.root + "test/fixtures/files/testImage.png" }
  let(:title)       { Faker::Lorem.sentence }
  let(:description) { Faker::Lorem.paragraph }

  scenario "Adding an attachment" do
    sign_in user
    visit "/businesses/#{business.id}"

    expect_to_be_on_business_page(business_id: business.id, business_name: business.trading_name)

    click_link "Add attachment"
    expect_to_be_on_add_attachment_to_a_business_upload_page(business_id: business.id)

    click_button "Upload"

    expect_to_be_on_add_attachment_to_a_business_upload_page(business_id: business.id)
    expect(page).to have_error_summary("Enter file")

    attach_file "document[file][file]", file
    click_button "Upload"

    expect_to_be_on_add_attachment_to_a_business_metadata_page(business_id: business.id)

    click_button "Save attachment"

    expect_to_be_on_add_attachment_to_a_business_metadata_page(business_id: business.id)
    expect(page).to have_error_summary("Enter title")

    fill_in "Document title", with: title
    fill_in "Description",    with: description

    click_button "Save attachment"

    expect_to_be_on_business_page(business_id: business.id, business_name: business.trading_name)
    expect_confirmation_banner("File has been added to the business")

    within "#attachments" do
      expect(page).to have_selector("h2", text: title)
      expect(page).to have_selector("p", text: description)
    end
  end
end
