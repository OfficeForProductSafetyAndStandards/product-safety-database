require "rails_helper"

RSpec.feature "Edit an investigation's reference number", :with_stubbed_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:original_reference_number) { '123' }
  let(:new_reference_number) { '999' }
  let(:investigation) { create(:allegation, complainant_reference: original_reference_number, creator: user) }

  it 'allows user to edit reference number' do
    sign_in(user)
    visit "/cases/#{investigation.pretty_id}"

    click_link "Edit reference number"

    expect(page.current_path).to eq "/cases/#{investigation.pretty_id}/reference_numbers/edit"
    expect(page).to have_css("h1", text: "Edit the reference number")

    expect(page).to have_field("complainant_reference", with: original_reference_number)

    fill_in :complainant_reference, with: new_reference_number

    click_button "Save"

    expect(page.current_path).to eq "/cases/#{investigation.pretty_id}"
    expect(page).to have_content "Reference number was successfully updated"

    expect(page.find("dt", text: "Trading Standards reference")).to have_sibling("dd", text: new_reference_number)
  end
end
