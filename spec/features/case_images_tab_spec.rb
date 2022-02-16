require "rails_helper"

RSpec.feature "Manage Images", :with_stubbed_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user)          { create(:user, :activated, has_viewed_introduction: true) }
  let(:other_user_different_org) { create(:user, :activated) }

  let(:investigation) { create(:allegation, creator: user) }
  let(:file)          { Rails.root.join "test/fixtures/files/testImage.png" }
  let(:title)         { Faker::Lorem.sentence }
  let(:description)   { Faker::Lorem.paragraph }

  before do
    ChangeCaseOwner.call!(investigation:, owner: user.team, user:)
    sign_in user
  end

  scenario "completing the add attachment flow saves the attachment" do
    visit "/cases/#{investigation.pretty_id}"

    click_link "Images"

    click_link "Add image"

    expect_to_be_on_add_image_page

    click_button "Save attachment"

    expect(page).to have_error_summary("Select a file", "Enter a document title")

    attach_and_submit_file

    expect_to_be_on_images_page
    expect_confirmation_banner("File has been added to the allegation")

    expect_case_images_page_to_show_entered_information

    click_link "Activity"

    expect_case_activity_page_to_show_entered_information

    # Test that another user in a different organisation can see case images
    sign_out

    sign_in(other_user_different_org)

    visit "/cases/#{investigation.pretty_id}/images"
    expect_to_be_on_images_page

    expect_case_images_page_to_show_entered_information

    click_link "Activity"

    expect_case_activity_page_to_show_entered_information
  end

  context "when case has products" do
    let(:product) { create(:product) }

    before do
      InvestigationProduct.create(investigation_id: investigation.id, product_id: product.id)
    end

    scenario "case images tab shows number of product images and number of case images" do
      visit "/cases/#{investigation.pretty_id}"

      expect(page).to have_content "Images (0)"

      click_link "Images"

      expect(page).to have_content "Case images (0)"
      expect(page).to have_content "Product images (0)"

      click_link "Add image"

      expect_to_be_on_add_image_page

      click_button "Save attachment"

      expect(page).to have_error_summary("Select a file", "Enter a document title")

      attach_and_submit_file

      expect_to_be_on_images_page
      expect_confirmation_banner("File has been added to the allegation")

      expect(page).to have_content "Images (1)"
      expect(page).to have_content "Case images (1)"
      expect(page).to have_content "Product images (0)"

      click_link "Product images"

      expect(page).to have_content "No attachments"

      click_link "Go to the #{product.name} product page"

      click_link "Images"

      click_link "Add image"

      attach_and_submit_file

      visit "/cases/#{investigation.pretty_id}"

      expect(page).to have_content "Images (2)"

      click_link "Images"

      expect(page).to have_content "Case images (1)"
      expect(page).to have_content "Product images (1)"
    end
  end

  def expect_case_activity_page_to_show_entered_information
    expect(page).to have_selector("h1", text: "Activity")
    item = page.find("h3", text: title).find(:xpath, "..")
    expect(item).to have_selector("p", text: "Image added")
    expect(item).to have_selector("p", text: description)
  end

  def expect_case_images_page_to_show_entered_information
    expect(page).to have_selector("h2", text: title)
    expect(page).to have_selector("p", text: description)
  end

  def attach_and_submit_file
    attach_file "document[document]", file
    fill_in "Document title", with: title
    fill_in "Description", with: description
    click_button "Save attachment"
  end
end
