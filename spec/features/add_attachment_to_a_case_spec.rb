require "rails_helper"

RSpec.feature "Add an attachment to a case", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user)          { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:allegation, creator: user) }

  let(:image_file)  { Rails.root + "test/fixtures/files/testImage.png" }
  let(:other_file)  { Rails.root + "test/fixtures/files/attachment_filename.txt" }
  let(:title)       { Faker::Lorem.sentence }
  let(:description) { Faker::Lorem.paragraph }

  scenario "Adding an attachment that is not an image" do
    sign_in user
    visit "/cases/#{investigation.pretty_id}/supporting-information/new"

    expect_to_be_on_add_supporting_information_page

    choose "Other document or attachment"
    click_button "Continue"

    expect_to_be_on_add_attachment_to_a_case_upload_page

    click_button "Upload"

    expect_to_be_on_add_attachment_to_a_case_upload_page
    expect(page).to have_error_summary("Enter file")

    attach_file "document[file][file]", other_file
    click_button "Upload"

    expect_to_be_on_add_attachment_to_a_case_metadata_page

    click_button "Save attachment"

    expect_to_be_on_add_attachment_to_a_case_metadata_page
    expect(page).to have_error_summary("Enter title")

    fill_in "Document title", with: title
    fill_in "Description",    with: description

    click_button "Save attachment"

    expect_to_be_on_supporting_information_page(case_id: investigation.pretty_id)
    expect_confirmation_banner("File has been added to the allegation")

    within page.find("h2", text: "Other files and attachments").find(:xpath, "..") do
      expect(page).to have_selector("h2", text: title)
      expect(page).to have_selector("p", text: description)
    end
  end

  scenario "Adding an image" do
    sign_in user
    visit "/cases/#{investigation.pretty_id}/supporting-information/new"

    expect_to_be_on_add_supporting_information_page

    choose "Other document or attachment"
    click_button "Continue"

    expect_to_be_on_add_attachment_to_a_case_upload_page

    attach_file "document[file][file]", image_file
    click_button "Upload"

    expect_to_be_on_add_attachment_to_a_case_metadata_page

    fill_in "Document title", with: title
    fill_in "Description",    with: description

    click_button "Save attachment"

    expect_to_be_on_images_page
    expect_confirmation_banner("File has been added to the allegation")

    expect(page).to have_selector("h2", text: title)
    expect(page).to have_selector("p", text: description)
  end
end
