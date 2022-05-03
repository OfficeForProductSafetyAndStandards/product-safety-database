require "rails_helper"

RSpec.feature "Add an attachment to a product", :with_stubbed_opensearch, :with_stubbed_antivirus, type: :feature do
  let(:user)    { create(:user, :activated, has_viewed_introduction: true) }
  let(:product) { create(:product) }

  let(:image)                 { Rails.root.join "test/fixtures/files/testImage.png" }
  let(:non_image_attachment)  { Rails.root.join "test/fixtures/files/attachment_filename.txt" }
  let(:title)                 { Faker::Lorem.sentence }
  let(:description)           { Faker::Lorem.paragraph }

  scenario "Adding an image" do
    sign_in user
    visit "/products/#{product.id}"

    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)

    click_link "Add image"
    expect_to_be_on_add_attachment_to_a_product_page(product_id: product.id)

    click_button "Save attachment"

    expect(page).to have_error_summary("Select a file", "Enter a document title")

    attach_file "document[document]", image
    fill_in "Document title", with: title
    fill_in "Description",    with: description

    click_button "Save attachment"

    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)
    expect_confirmation_banner("The image was added")

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
    expect_to_be_on_add_attachment_to_a_product_page(product_id: product.id)

    click_button "Save attachment"

    expect(page).to have_error_summary("Select a file", "Enter a document title")

    attach_file "document[document]", non_image_attachment
    fill_in "Document title", with: title
    fill_in "Description",    with: description

    click_button "Save attachment"

    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)
    expect_confirmation_banner("The file was added")

    within "#attachments" do
      expect(page).to have_selector("h2", text: title)
      expect(page).to have_selector("p", text: description)
    end
  end
end
