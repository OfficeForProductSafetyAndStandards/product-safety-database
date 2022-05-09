require "rails_helper"

RSpec.feature "Add an attachment to a product", :with_stubbed_opensearch, :with_stubbed_antivirus, type: :feature do
  let(:user)    { create(:user, :activated, has_viewed_introduction: true) }
  let(:product) { create(:product) }

  let(:image)                 { Rails.root.join "test/fixtures/files/testImage.png" }
  let(:non_image_attachment)  { Rails.root.join "test/fixtures/files/attachment_filename.txt" }
  let(:title)                 { Faker::Lorem.sentence }
  let(:description)           { Faker::Lorem.paragraph }

  scenario "Adding an image", :with_stubbed_antivirus do
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

    expect(page).to have_selector("h2", text: title)
    expect(page).to have_selector("p", text: description)

    change_attachment_to_have_simulate_virus(product.reload)

    visit "/products/#{product.id}"

    click_link "Images (0)"

    expect(page).not_to have_selector("h2", text: title)
    expect(page).not_to have_selector("p", text: description)
  end

  scenario "Adding an attachment", :with_stubbed_antivirus do
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

    expect(page).to have_selector("h2", text: title)
    expect(page).to have_selector("p", text: description)

    change_attachment_to_have_simulate_virus(product.reload)

    click_link "Attachments (0)"

    expect(page).not_to have_selector("h2", text: title)
    expect(page).not_to have_selector("p", text: description)
  end

  context "when an imagine fails the antivirus check", :with_stubbed_failing_antivirus do
    it "shows error" do
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

      errors_list = page.find(".govuk-error-summary__list").all("li")
      expect(errors_list[0].text).to eq "Files must be virus free"
    end
  end

  def change_attachment_to_have_simulate_virus(product)
    blob = product.documents.first.blob
    blob.update(metadata: blob.metadata.merge(safe: false))
  end
end
