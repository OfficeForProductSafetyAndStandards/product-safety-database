require "rails_helper"

RSpec.feature "Add/edit/remove an attachment for a product", :with_stubbed_antivirus, type: :feature do
  let(:user)    { create(:user, :activated, has_viewed_introduction: true) }
  let(:product) { create(:product, owning_team: user.team) }

  let(:image)                 { Rails.root.join "test/fixtures/files/testImage.png" }
  let(:non_image_attachment)  { Rails.root.join "test/fixtures/files/attachment_filename.txt" }
  let(:title)                 { Faker::Lorem.sentence }
  let(:description)           { Faker::Lorem.paragraph }
  let(:new_title)             { Faker::Lorem.sentence }
  let(:new_description)       { Faker::Lorem.paragraph }

  scenario "Adding an image", :with_stubbed_antivirus do
    sign_in user
    visit "/products/#{product.id}"

    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)

    click_link "Add an image"
    expect_to_be_on_add_attachment_to_a_product_page(product_id: product.id)

    click_button "Save attachment"

    expect(page).to have_error_summary("File upload cannot be blank", "Title cannot be blank")

    attach_file "document_upload[file_upload]", image
    fill_in "Document title", with: title
    fill_in "Description",    with: description

    click_button "Save attachment"

    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)
    expect_confirmation_banner("The image was added")

    expect(page).to have_selector("figcaption", text: title)
    expect(page).to have_selector("dd.govuk-summary-list__value", text: description)

    change_attachment_to_have_simulated_virus(product.reload)

    visit "/products/#{product.id}"

    click_link "Images (0)"

    expect(page).not_to have_selector("figcaption", text: title)
    expect(page).not_to have_selector("dd.govuk-summary-list__value", text: description)
  end

  scenario "Editing an image" do
    sign_in user
    visit "/products/#{product.id}"

    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)

    click_link "Add an image"
    expect_to_be_on_add_attachment_to_a_product_page(product_id: product.id)

    attach_file "document_upload[file_upload]", image
    fill_in "Document title", with: title
    fill_in "Description",    with: description

    click_button "Save attachment"

    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)
    expect_confirmation_banner("The image was added")

    expect(page).to have_selector("figcaption", text: title)
    expect(page).to have_selector("dd.govuk-summary-list__value", text: description)

    click_link "Edit this image"
    expect_to_be_on_edit_attachment_for_a_product_page(product_id: product.id, document_upload_id: product.reload.virus_free_images.first.id)

    fill_in "Document title", with: new_title
    fill_in "Description",    with: new_description

    click_button "Update attachment"

    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)
    expect_confirmation_banner("The image was updated")

    expect(page).to have_selector("figcaption", text: new_title)
    expect(page).to have_selector("dd.govuk-summary-list__value", text: new_description)
  end

  scenario "Deleting an image" do
    sign_in user
    visit "/products/#{product.id}"

    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)

    click_link "Add an image"
    expect_to_be_on_add_attachment_to_a_product_page(product_id: product.id)

    attach_file "document_upload[file_upload]", image
    fill_in "Document title", with: title
    fill_in "Description",    with: description

    click_button "Save attachment"

    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)
    expect_confirmation_banner("The image was added")

    expect(page).to have_selector("figcaption", text: title)
    expect(page).to have_selector("dd.govuk-summary-list__value", text: description)

    click_link "Remove this image"
    expect_to_be_on_delete_attachment_for_a_product_page(product_id: product.id, document_upload_id: product.reload.virus_free_images.first.id)

    expect(page).to have_selector("td.govuk-table__cell", text: title)
    expect(page).to have_selector("td.govuk-table__cell", text: description)

    click_button "Delete attachment"

    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)
    expect_confirmation_banner("The image was successfully removed")

    expect(page).not_to have_selector("figcaption", text: title)
    expect(page).not_to have_selector("dd.govuk-summary-list__value", text: description)
  end

  context "when an image fails the antivirus check", :with_stubbed_failing_antivirus do
    it "shows error" do
      sign_in user
      visit "/products/#{product.id}"

      expect_to_be_on_product_page(product_id: product.id, product_name: product.name)

      click_link "Add an image"
      expect_to_be_on_add_attachment_to_a_product_page(product_id: product.id)

      click_button "Save attachment"

      expect(page).to have_error_summary("File upload cannot be blank", "Title cannot be blank")

      attach_file "document_upload[file_upload]", non_image_attachment
      fill_in "Document title", with: title
      fill_in "Description",    with: description

      click_button "Save attachment"

      expect_warning_banner("The file did not finish uploading - you must refresh the file")
    end
  end

  context "when the product is owned by another team" do
    let(:owning_team) { create(:team) }
    let(:owning_user) { create(:user, :activated, has_viewed_introduction: true, team: owning_team) }
    let(:product) { create(:product, owning_team:) }

    it "does not allow the user to add attachments" do
      sign_in user
      visit "/products/#{product.id}"

      expect(page).not_to have_link("Add an image")

      expect { visit("/products/#{product.id}/document_uploads/new") }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "does not allow the user to edit or delete attachments" do
      sign_in owning_user
      visit "/products/#{product.id}"

      expect_to_be_on_product_page(product_id: product.id, product_name: product.name)

      click_link "Add an image"

      attach_file "document_upload[file_upload]", image
      fill_in "Document title", with: title
      fill_in "Description",    with: description

      click_button "Save attachment"

      expect_to_be_on_product_page(product_id: product.id, product_name: product.name)
      expect_confirmation_banner("The image was added")

      expect(page).to have_link("Edit this image")
      expect(page).to have_link("Remove this image")

      click_on "Sign out", match: :first

      expect(page).to have_current_path("/")

      sign_in user
      visit "/products/#{product.reload.id}"

      expect_to_be_on_product_page(product_id: product.id, product_name: product.name)

      expect(page).not_to have_link("Add an image")
      expect(page).not_to have_link("Edit image")
      expect(page).not_to have_link("Delete image")

      expect { visit("/products/#{product.id}/document_uploads/#{product.virus_free_images.last.id}/edit") }.to raise_error(Pundit::NotAuthorizedError)
      expect { visit("/products/#{product.id}/document_uploads/#{product.virus_free_images.last.id}/remove") }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  def change_attachment_to_have_simulated_virus(product)
    blob = product.document_uploads.first.file_upload.blob
    blob.update!(metadata: blob.metadata.merge(safe: false))
  end
end
