require "rails_helper"

RSpec.feature "Add/edit/remove an attachment for a product", :with_stubbed_antivirus, type: :feature do
  let(:user)    { create(:user, :activated, has_viewed_introduction: true) }
  let(:product) { create(:product, owning_team: user.team) }
  let(:image) { Rails.root.join "test/fixtures/files/testImage.png" }

  scenario "Adding an image", :with_stubbed_antivirus do
    sign_in user
    visit "/products/#{product.id}"

    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)

    click_link "Add an image"
    expect_to_be_on_add_attachment_to_a_product_page(product_id: product.id)

    click_button "Upload"

    expect(page).to have_error_summary("Select a file")

    attach_file "image_upload[file_upload]", image

    click_button "Upload"

    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)
    expect_confirmation_banner("The image was uploaded")

    change_attachment_to_have_simulated_virus(product.reload)

    visit "/products/#{product.id}"

    click_link "Images (0)"
  end

  scenario "Deleting an image" do
    sign_in user
    visit "/products/#{product.id}"

    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)

    click_link "Add an image"
    expect_to_be_on_add_attachment_to_a_product_page(product_id: product.id)

    attach_file "image_upload[file_upload]", image

    click_button "Upload"

    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)
    expect_confirmation_banner("The image was uploaded")

    click_link "Remove this image"
    expect_to_be_on_delete_attachment_for_a_product_page(product_id: product.id, image_upload_id: product.reload.virus_free_images.first.id)

    click_button "Delete image"

    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)
    expect_confirmation_banner("The image was successfully removed")
  end

  context "when an image fails the antivirus check", :with_stubbed_failing_antivirus do
    it "shows error" do
      sign_in user
      visit "/products/#{product.id}"

      expect_to_be_on_product_page(product_id: product.id, product_name: product.name)

      click_link "Add an image"
      expect_to_be_on_add_attachment_to_a_product_page(product_id: product.id)

      click_button "Upload"

      expect(page).to have_error_summary("Select a file")

      attach_file "image_upload[file_upload]", image

      click_button "Upload"

      expect_warning_banner("File upload must be virus free")
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

      visit("/products/#{product.id}/document_uploads/new")
      expect(page).to have_http_status(:forbidden)
    end

    it "does not allow the user to edit or delete images" do
      sign_in owning_user
      visit "/products/#{product.id}"

      expect_to_be_on_product_page(product_id: product.id, product_name: product.name)

      click_link "Add an image"

      attach_file "image_upload[file_upload]", image

      click_button "Upload"

      expect_to_be_on_product_page(product_id: product.id, product_name: product.name)
      expect_confirmation_banner("The image was uploaded")

      expect(page).to have_link("Remove this image")

      click_on "Sign out", match: :first

      expect(page).to have_current_path("/")

      sign_in user
      visit "/products/#{product.reload.id}"

      expect_to_be_on_product_page(product_id: product.id, product_name: product.name)

      expect(page).not_to have_link("Add an image")
      expect(page).not_to have_link("Delete image")

      visit("/products/#{product.id}/image_uploads/#{product.virus_free_images.last.id}/remove")
      expect(page).to have_http_status(:forbidden)
    end
  end

  def change_attachment_to_have_simulated_virus(product)
    blob = product.image_uploads.first.file_upload.blob
    blob.update!(metadata: blob.metadata.merge(safe: false))
  end
end
