require "rails_helper"

RSpec.feature "Add an attachment to a product", :with_stubbed_elasticsearch, :with_stubbed_antivirus, type: :feature do
  let(:user)    { create(:user, :activated, has_viewed_introduction: true) }
  let(:product) { create(:product) }

  let(:image)                 { Rails.root.join "test/fixtures/files/testImage.png" }
  let(:non_image_attachment)  { Rails.root.join "test/fixtures/files/email_file.txt" }
  let(:title)                 { Faker::Lorem.sentence }
  let(:description)           { Faker::Lorem.paragraph }

  scenario "Adding an image" do
    sign_in user
    visit "/products/#{product.id}"

    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)

    click_link "Add image"
    expect_to_be_on_add_attachment_to_a_product_upload_page(product_id: product.id)

    click_button "Upload"

    expect_to_be_on_add_attachment_to_a_product_upload_page(product_id: product.id)
    expect(page).to have_error_summary("Enter file")

    attach_file "document[file][file]", image
    click_button "Upload"

    expect_to_be_on_add_attachment_to_a_product_metadata_page(product_id: product.id)

    click_button "Save attachment"

    expect_to_be_on_add_attachment_to_a_product_metadata_page(product_id: product.id)
    expect(page).to have_error_summary("Enter title")

    fill_in "Document title", with: title
    fill_in "Description",    with: description

    click_button "Save attachment"

    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)
    expect_confirmation_banner("File has been added to the product")

    within "#images" do
      expect(page).to have_selector("h2", text: title)
      expect(page).to have_selector("p", text: description)
    end
  end

  scenario "Adding an attachment" do
    sign_in user
    visit "/products/#{product.id}"

    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)

    click_link "Add attachment"
    expect_to_be_on_add_attachment_to_a_product_upload_page(product_id: product.id)

    click_button "Upload"

    expect_to_be_on_add_attachment_to_a_product_upload_page(product_id: product.id)
    expect(page).to have_error_summary("Enter file")

    attach_file "document[file][file]", non_image_attachment
    click_button "Upload"

    expect_to_be_on_add_attachment_to_a_product_metadata_page(product_id: product.id)

    click_button "Save attachment"

    expect_to_be_on_add_attachment_to_a_product_metadata_page(product_id: product.id)
    expect(page).to have_error_summary("Enter title")

    fill_in "Document title", with: title
    fill_in "Description",    with: description

    click_button "Save attachment"

    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)
    expect_confirmation_banner("File has been added to the product")

    within "#attachments" do
      expect(page).to have_selector("h2", text: title)
      expect(page).to have_selector("p", text: description)
    end
  end
end
