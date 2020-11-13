require "rails_helper"

RSpec.feature "Manage Images", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user)          { create(:user, :activated, has_viewed_introduction: true) }
  let(:other_user_different_org) { create(:user, :activated) }

  let(:investigation) { create(:allegation, creator: user) }
  let(:file)          { Rails.root + "test/fixtures/files/testImage.png" }
  let(:title)         { Faker::Lorem.sentence }
  let(:description)   { Faker::Lorem.paragraph }

  before do
    ChangeCaseOwner.call!(investigation: investigation, owner: user.team, user: user)
    sign_in user
  end

  scenario "completing the add attachment flow saves the attachment" do
    visit "/cases/#{investigation.pretty_id}"

    click_link "Images"

    expect_uploading_a_file_without_completing_the_add_image_flow_does_not_save_the_image

    expect_requires_a_file

    expect_requires_a_title_for_the_document

    expect_to_be_on_enter_image_details_page

    fill_and_submit_attachment_details_page

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

  def expect_uploading_a_file_without_completing_the_add_image_flow_does_not_save_the_image
    click_link "Add image"

    attach_and_submit_file

    visit investigation_path(investigation)

    click_link "Images"

    expect(page).not_to have_selector("h2")
  end

  def expect_requires_a_file
    click_link "Add image"

    expect_to_be_on_add_image_page

    click_button "Upload"

    expect_to_be_on_add_image_page
    expect(page).to have_error_summary("Enter file")
  end

  def expect_requires_a_title_for_the_document
    expect_to_be_on_add_image_page

    attach_and_submit_file

    expect_to_be_on_enter_image_details_page

    click_button "Save attachment"

    expect_to_be_on_enter_image_details_page
    expect(page).to have_error_summary("Enter title")
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
    attach_file "document[file][file]", file
    click_button "Upload"
  end

  def fill_and_submit_attachment_details_page
    fill_in "Document title", with: title
    fill_in "Description", with: description
    click_button "Save attachment"
  end
end
