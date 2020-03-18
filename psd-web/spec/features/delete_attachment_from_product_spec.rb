require "rails_helper"

RSpec.feature "Deleting an attachment from a product", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_keycloak_config, type: :feature do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:product) { create(:product, :with_document) }
  let(:document) { product.documents.first }

  before { sign_in(as_user: user) }

  scenario "deletes the attachment" do
    visit "/products/#{product.id}"

    expect_to_be_on_product_page

    click_link "Attachments"

    expect_to_be_on_product_attachments_page

    click_link "Remove document"

    expect_to_be_on_remove_attachment_confirmation_page
    expect_remove_attachment_confirmation_page_to_show_attachment_information

    click_button "Delete attachment"

    expect_to_be_on_product_page

    click_link "Attachments"

    expect_product_attachments_page_not_to_show_deleted_attachment
  end

  def expect_to_be_on_product_attachments_page
    expect(page).to have_selector("h2", text: "Attachments")
    expect(page).to have_selector("h2", text: document.title)
    expect(page).to have_selector("p",  text: document.description)
  end

  def expect_to_be_on_remove_attachment_confirmation_page
    expect(page).to have_current_path("/products/#{product.id}/documents/#{document.id}/remove")
    expect(page).to have_selector("h2", text: "Remove attachment")
    expect(page).to have_link("Back", href: "/products/#{product.id}")
  end

  def expect_to_be_on_product_page
    expect(page).to have_current_path("/products/#{product.id}")
    expect(page).to have_selector("h1", text: product.name)
  end

  def expect_remove_attachment_confirmation_page_to_show_attachment_information
    expect(page.find("th", text: "Title")).to have_sibling("td", text: document.title)
    expect(page.find("th", text: "Description")).to have_sibling("td", text: document.description)
    expect(page.find("th", text: "URL")).to have_sibling("td", text: document.filename)
  end

  def expect_product_attachments_page_not_to_show_deleted_attachment
    expect(page).not_to have_selector("h2", text: document.title)
    expect(page).not_to have_selector("p",  text: document.description)
  end
end
