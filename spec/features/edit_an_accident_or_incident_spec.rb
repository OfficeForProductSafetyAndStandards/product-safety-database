require "rails_helper"

RSpec.feature "Editing an accident or incident on a case", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated, name: "Joe Bloggs") }
  let(:teddy_bear) { create(:product, name: "Teddy Bear") }
  let(:doll) { create(:product, name: "Doll") }

  let(:investigation) do
    create(:allegation,
           creator: user,
           risk_level: :serious,
           products: [teddy_bear, doll])
  end

  let(:team) { create(:team, name: "MyCouncil Trading Standards") }

  let!(:accident_or_incident) do
    create(:incident,
           date: nil,
           is_date_known: "no",
           product: doll,
           severity: "serious",
           usage: "during_normal_use",
           investigation: investigation)
  end

  scenario "Editing a risk assessment (with validation errors)" do
    sign_in(user)
    visit "/cases/#{investigation.pretty_id}"

    click_link "Supporting information (1)"

    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/supporting-information")

    click_link "During normal use: Doll"

    click_link "Edit Incident"

    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/accident_or_incidents/#{accident_or_incident.id}/edit")

    within_fieldset("Do you know when the Incident happened?") do
      expect(page).to have_checked_field("No")
    end

    expect(page).to have_select("Select the product linked to this Incident", selected: 'Doll')

    within_fieldset("Indicate the severity") do
      expect(page).to have_checked_field("Serious")
    end

    within_fieldset("How was the product being used at the time of this Incident") do
      expect(page).to have_checked_field("During normal use")
    end

    choose("Yes")
    fill_in("Day", with: "3")
    fill_in("Month", with: "4")
    fill_in("Year", with: "2020")

    select "Teddy Bear", from: "Select the product linked to this Incident"

    choose("Other")
    fill_in "Other type", with: "Test"

    choose("During misuse")

    fill_in("Additional information (optional)", with: "Some additional stuff you should know")

    click_button "Update Incident"

    expect(page).not_to have_error_messages

    expect(page).to have_content "Incident: Teddy Bear"

    click_link "Back to allegation: #{investigation.pretty_id}"

    click_on "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

    expect(page).to have_selector("h1", text: "Activity")

    item = page.find("h3", text: "Accident or Incident").find(:xpath, "..")
    expect(item).to have_text("Date of Incident: #{Date.new(2020, 04, 03)}")
    expect(item).to have_text("Teddy Bear")
    expect(item).to have_text("Severity: Test")
    expect(item).to have_text("Product usage: During misuse")
  end
end
