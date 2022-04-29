require "rails_helper"

RSpec.feature "Add an attachment to a case", :with_stubbed_opensearch, :with_stubbed_mailer, :with_stubbed_antivirus, type: :feature do
  let(:user)          { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:allegation, creator: user) }

  let(:image_file)  { Rails.root.join "test/fixtures/files/testImage.png" }
  let(:other_file)  { Rails.root.join "test/fixtures/files/attachment_filename.txt" }
  let(:title)       { Faker::Lorem.sentence }
  let(:description) { Faker::Lorem.paragraph }

  scenario "Adding an attachment that is not an image" do
    sign_in user
    visit "/cases/#{investigation.pretty_id}/supporting-information/new"

    expect_to_be_on_add_supporting_information_page

    choose "Other document or attachment"
    click_button "Continue"

    expect_to_be_on_add_attachment_to_a_case_page

    click_button "Save attachment"

    expect(page).to have_error_summary("Select a file", "Enter a document title")

    attach_file "document[document]", other_file
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

    expect_to_be_on_add_attachment_to_a_case_page

    attach_file "document[document]", image_file
    fill_in "Document title", with: title
    fill_in "Description",    with: description

    click_button "Save attachment"

    expect_to_be_on_images_page
    expect_confirmation_banner("The image was added")

    expect(page).to have_selector("h2", text: title)
    expect(page).to have_selector("p", text: description)
  end

  context "when it fails the antivirus check", :with_stubbed_failing_antivirus do
    it "shows error" do
      sign_in user
      visit "/cases/#{investigation.pretty_id}/supporting-information/new"

      expect_to_be_on_add_supporting_information_page

      choose "Other document or attachment"
      click_button "Continue"

      expect_to_be_on_add_attachment_to_a_case_page

      attach_file "document[document]", image_file
      fill_in "Document title", with: title
      fill_in "Description",    with: description

      click_button "Save attachment"

      expect(page).to have_current_path("/cases/#{investigation.pretty_id}/images")

      errors_list = page.find(".govuk-error-summary__list").all("li")
      expect(errors_list[0].text).to eq "One or more images failed to upload. Image files must be virus free"
    end
  end

  # rubocop:disable RSpec/AnyInstance
  context "when image is too large" do
    it "shows error" do
      allow_any_instance_of(DocumentForm).to receive(:max_file_byte_size) { 1.kilobytes }
      sign_in user
      visit "/cases/#{investigation.pretty_id}/supporting-information/new"

      expect_to_be_on_add_supporting_information_page

      choose "Other document or attachment"
      click_button "Continue"

      expect_to_be_on_add_attachment_to_a_case_page

      attach_file "document[document]", image_file
      fill_in "Document title", with: title
      fill_in "Description",    with: description

      click_button "Save attachment"

      expect(page).to have_current_path("/cases/#{investigation.pretty_id}/documents")

      errors_list = page.find(".govuk-error-summary__list").all("li")
      expect(errors_list[0].text).to eq "Files must be smaller than 0 MB in size"
    end
    # rubocop:enable RSpec/AnyInstance
  end
end
