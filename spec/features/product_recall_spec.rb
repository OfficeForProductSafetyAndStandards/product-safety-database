require "rails_helper"
require "find"
RSpec.feature "Product Recall Spec", :with_product_form_helper, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:organisation) { Organisation.create!(name: "Office for Product Safety and Standards") }
  let(:user) { create(:user, :activated, team: Team.create!(name: "OPSS Incident Management", team_recipient_email: nil, organisation:, country: "country:GB")) }
  let(:notification) { create(:notification, :with_complainant, :with_business, :with_document, :reported_unsafe_and_non_compliant) }
  let(:attributes) do
    attributes_for(:product_iphone, authenticity: Product.authenticities.keys.without("missing", "unsure").sample)
  end
  let(:product) do
    create(:product_iphone,
           authenticity: "counterfeit",
           has_markings: "markings_yes",
           owning_team: user.team)
  end
  let(:image) { Rails.root.join "test/fixtures/files/testImage.png" }
  let(:image2) { Rails.root.join "test/fixtures/files/testImage2.png" }

  before do
    sign_in(user)
    product
    notification
    AddProductToNotification.call!(user:, notification:, product:)
    marketplaces = [
      "Amazon",
      "eBay",
      "AliExpress",
      "Wish",
      "Etsy",
      "AliBaba",
      "Asos Marketplace",
      "Banggood",
      "Bonanza",
      "Depop",
      "DesertCart",
      "Ecrater",
      "Facebook Marketplace",
      "Farfetch",
      "Fishpond",
      "Folksy",
      "ForDeal",
      "Fruugo",
      "Grandado",
      "Groupon",
      "Gumtree",
      "Houzz",
      "Instagram",
      "Joom",
      "Light In The Box",
      "OnBuy",
      "NotOnTheHighStreet",
      "Manomano",
      "PatPat",
      "Pinterest",
      "Rakuten",
      "Shein",
      "Shpock",
      "Stockx",
      "Temu",
      "Vinted",
      "Wayfair",
      "Wowcher",
      "Zalando"
    ]
    marketplaces.each do |marketplace|
      OnlineMarketplace.create(name: marketplace, approved_by_opss: true)
    end
  end

  scenario "Creating a product recall for a product with no images" do
    visit "/products/#{product.id}"

    expect_to_be_on_product_page(product_id: Product.last.id, product_name: Product.last.name)

    click_link "product recall formatting tool"

    expect_to_be_on_product_recall_page(product_id: Product.last.id)
    click_link "Start now"

    expect(page).to have_h1("Select the images to include")
    expect(page).to have_text("Images have not been added to the PSD product record.")

    click_button "Continue"

    within_fieldset "Counterfeit" do
      choose(%w[Yes No Unsure].sample)
    end

    within_fieldset "Risk level" do
      choose(%w[Serious High Medium Low].sample)
    end

    within_fieldset "Notified by" do
      radio_button_count = all('input[type="radio"]').count
      expect(radio_button_count).to eq(8)
      radio_button = find('input[type="radio"][id="product-recall-form-notified-by-medicines-and-healthcare-products-regulatory-agency-mhra-field"]')
      expect(radio_button[:value]).to eq("Medicines and Healthcare products Regulatory Agency (MHRA)")
      choose("Medicines and Healthcare products Regulatory Agency (MHRA)")
    end

    click_button "Continue"

    expect(find("textarea#markdown_template_product_safety_report").value).to have_text("Medicines and Healthcare products Regulatory Agency (MHRA)")
    expect(find("textarea#markdown_template_product_recall").value).to have_text("Medicines and Healthcare products Regulatory Agency (MHRA)")

    download = page.all("button", text: "Download the PDF").first
    download.click
    # clicking button sends to page with PDF on it
    expect(page).to have_current_path("/products/#{product.id}/recalls/pdf")
  end

  scenario "Creating a product recall with images" do
    visit "/products/#{product.id}"

    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)

    click_link "Add an image"
    expect_to_be_on_add_attachment_to_a_product_page(product_id: product.id)

    click_button "Upload"

    expect(page).to have_error_summary("Select a file")

    attach_file "image_upload[file_upload]", image

    click_button "Upload"

    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)

    visit "/products/#{product.id}"
    click_link "product recall formatting tool"

    expect_to_be_on_product_recall_page(product_id: Product.last.id)

    puts product.country_of_origin
    click_link "Start now"

    within_fieldset "Select the images to include" do
      check(image.to_s.split("/")[-1])
    end

    click_button "Continue"

    within_fieldset "Counterfeit" do
      choose(%w[Yes No Unsure].sample)
    end

    within_fieldset "Risk level" do
      choose(%w[Serious High Medium Low].sample)
    end

    within_fieldset "Notified by" do
      radio_button_count = all('input[type="radio"]').count
      expect(radio_button_count).to eq(8)
      radio_button = find('input[type="radio"][id="product-recall-form-notified-by-medicines-and-healthcare-products-regulatory-agency-mhra-field"]')
      expect(radio_button[:value]).to eq("Medicines and Healthcare products Regulatory Agency (MHRA)")
      choose("Medicines and Healthcare products Regulatory Agency (MHRA)")
    end

    click_button "Continue"

    expect(find("textarea#markdown_template_product_safety_report").value).to have_text("Medicines and Healthcare products Regulatory Agency (MHRA)")
    expect(find("textarea#markdown_template_product_recall").value).to have_text("Medicines and Healthcare products Regulatory Agency (MHRA)")

    download = page.all("button", text: "Download the PDF").first
    download.click
    # clicking button sends to page with PDF on it
    expect(page).to have_current_path("/products/#{product.id}/recalls/pdf")
  end
end
