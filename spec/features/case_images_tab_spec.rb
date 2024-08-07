require "rails_helper"

RSpec.feature "Case images", :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:other_user_different_org) { create(:user, :activated) }

  let(:notification) { create(:allegation, creator: user) }
  let(:file) { Rails.root.join "test/fixtures/files/testImage.png" }
  let(:file_name) { "testImage.png" }

  before do
    ChangeNotificationOwner.call!(notification:, owner: user.team, user:)
    sign_in user
  end

  scenario "completing the add image flow saves the image" do
    visit "/cases/#{notification.pretty_id}"

    click_link "Images"

    click_link "Add a notification image"

    expect_to_be_on_add_image_page

    click_button "Upload"

    expect(page).to have_error_summary("Select a file")

    attach_and_submit_file

    expect_to_be_on_add_image_page(image_upload_id: notification.reload.image_uploads.first.id)
    expect_confirmation_banner("The image was uploaded")

    visit "/cases/#{notification.pretty_id}/images"

    expect_to_be_on_images_page

    click_link "Activity"

    expect_case_activity_page_to_show_entered_information

    # Test that another user in a different organisation can see case images
    sign_out

    sign_in(other_user_different_org)

    visit "/cases/#{notification.pretty_id}/images"

    expect_to_be_on_images_page

    click_link "Activity"

    expect_case_activity_page_to_show_entered_information
  end

  context "when case has products" do
    let(:product) { create(:product) }

    before do
      InvestigationProduct.create(investigation_id: notification.id, product_id: product.id)
    end

    scenario "case images tab numbers the case images" do
      visit "/cases/#{notification.pretty_id}"

      expect(page).to have_content "Images (0)"

      click_link "Images"

      expect(page).to have_content "This notification does not have any notification evidence images."

      click_link "Add a notification image"

      expect_to_be_on_add_image_page

      click_button "Upload"

      expect(page).to have_error_summary("Select a file")

      attach_and_submit_file

      expect_to_be_on_add_image_page(image_upload_id: notification.reload.image_uploads.first.id)
      expect_confirmation_banner("The image was uploaded")

      click_link "Finish uploading images"

      expect_to_be_on_images_page
      expect(page).to have_content "Images (1)"
      expect(page).to have_content "Notification image 1"
    end
  end

  def expect_case_activity_page_to_show_entered_information
    expect(page).to have_selector("h1", text: "Activity")
    item = page.find("h3", text: file_name).find(:xpath, "..")
    expect(item).to have_selector("p", text: "Image added")
  end

  def attach_and_submit_file
    attach_file "image_upload[file_upload]", file
    click_button "Upload"
  end
end
