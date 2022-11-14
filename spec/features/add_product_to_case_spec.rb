require "rails_helper"

RSpec.feature "Adding a product to a case", :with_stubbed_mailer, :with_stubbed_opensearch do
  let(:user)          { create(:user, :opss_user, :activated) }
  let(:investigation) { create(:enquiry, creator: user) }
  let(:other_user)    { create(:user, :activated) }
  let(:right_product) { create(:product) }
  let(:wrong_product) { create(:product) }

  scenario "Finding and linking an existing product" do
    sign_in user
    visit "/cases/#{investigation.pretty_id}/products"

    click_link "Add a product to the case"

    expect(page).to have_text("Enter a PSD product record reference number")

    click_button "Continue"

    expect(page).to have_error_summary
    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Enter a PSD product record reference number"

    fill_in "reference", with: "invalid"

    click_button "Continue"

    expect(page).to have_error_summary
    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Enter a PSD product record reference number"

    fill_in "reference", with: "PsD-#{wrong_product.id}"

    click_button "Continue"

    expect(page).to have_text("Is this the correct product record to add to your case?")
    expect(page).to have_text("#{wrong_product.brand} #{wrong_product.name}")

    click_button "Save and continue"

    expect(page).to have_error_summary
    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Select yes if this is the correct product record to add to your case"

    choose "No - Enter the PSD reference number again"
    click_button "Save and continue"

    expect(page).to have_text("Enter a PSD product record reference number")

    fill_in "reference", with: right_product.id
    click_button "Continue"

    expect(page).to have_text("Is this the correct product record to add to your case?")
    expect(page).to have_text("#{right_product.brand} #{right_product.name}")

    choose "Yes"
    click_button "Save and continue"

    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/products")
    expect(page).to have_text("The product record was added to the case")

    click_link "Add a product to the case"

    fill_in "reference", with: right_product.id
    click_button "Continue"

    expect(page).to have_error_summary
    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Enter a product record which has not already been added to the case"

    close_case_change_product_then_reopen_it

    click_button "Continue"

    expect(page).to have_text("Is this the correct product record to add to your case?")
    expect(page).to have_text("#{right_product.brand} #{right_product.name}")

    choose "Yes"
    click_button "Save and continue"

    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/products")
    expect(page).to have_text("The product record was added to the case")

    expect(page).to have_selector("h3", text: right_product.name)
    expect(page).to have_css(".govuk-summary-list__value", text: "#{right_product.psd_ref} - The PSD reference for this version of the product record")
    "psd-2 - The PSD reference for this version of the product record - as recorded when the case was closed: 14 November 2022."
    expect(page).to have_css(".govuk-summary-list__value", text:  "#{right_product.psd_ref}_#{investigation.reload.investigation_products.first.investigation_closed_at.to_i} - The PSD reference for this version of the product record - as recorded when the case was closed: #{investigation.reload.investigation_products.first.investigation_closed_at.to_s(:govuk)}." )
    expect(investigation.reload.products.count).to eq(2)
    expect(investigation.products.first).to eq(right_product)
    expect(right_product.reload.owning_team).to eq(investigation.owner_team)
    expect(page).to have_content "This product record has also been added to these 1 cases."

    click_link "Activity"

    expect(page).to have_selector("h3", text: right_product.name)
    expect(page).to have_text("Product added by #{user.name}")
  end

  scenario "Not being able to add a product to another team’s case" do
    sign_in other_user
    visit "/cases/#{investigation.pretty_id}/products"

    expect(page).not_to have_link("Add a product to the case")
  end

  def close_case_change_product_then_reopen_it
    ChangeCaseStatus.call!(investigation: investigation, new_status: "closed", user: user)
    Product.update(description: "wowthisisnew!")
    ChangeCaseStatus.call!(investigation: investigation, new_status: "open", user: user)
  end
end
