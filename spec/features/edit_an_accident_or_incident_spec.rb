require "rails_helper"

RSpec.feature "Editing an accident or incident on a case", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated, name: "Joe Bloggs") }
  let(:teddy_bear) { create(:product, name: "Teddy Bear") }
  let(:doll) { create(:product, name: "Doll") }
  let(:date) { Date.current }

  let(:investigation) do
    create(:allegation,
           creator: user,
           risk_level: :serious,
           products: [teddy_bear, doll])
  end

  let(:team) { create(:team, name: "MyCouncil Trading Standards") }

  let!(:incident) do
    create(:incident,
           date: nil,
           is_date_known: false,
           product: doll,
           severity: "serious",
           usage: "during_normal_use",
           investigation: investigation)
  end

  let!(:accident) do
    create(:accident,
           date: Date.current,
           is_date_known: true,
           product: teddy_bear,
           severity: "other",
           severity_other: "very extreme",
           usage: "during_normal_use",
           investigation: investigation)
  end

  scenario "Editing an incident, setting date to known, (with validation errors)" do
    sign_in(user)
    visit "/cases/#{investigation.pretty_id}"

    click_link "Supporting information (2)"

    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/supporting-information")

    click_link "During normal use: Doll"

    click_link "Edit incident"

    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/accident_or_incidents/#{incident.id}/edit")

    within_fieldset("Do you know when the incident happened?") do
      expect(page).to have_checked_field("No")
    end

    expect(page).to have_select("Select the product linked to this incident", selected: "Doll")

    within_fieldset("Indicate the severity") do
      expect(page).to have_checked_field("Serious")
    end

    within_fieldset("How was the product being used at the time of this incident") do
      expect(page).to have_checked_field("During normal use")
    end

    choose("Yes")
    fill_in("Day", with: date.day)
    fill_in("Month", with: date.month)
    fill_in("Year", with: date.year)

    select "Teddy Bear", from: "Select the product linked to this incident"

    choose("Other")
    fill_in "Other type", with: "Test"

    choose("During misuse")

    fill_in("Additional information (optional)", with: "Some additional stuff you should know")

    click_button "Update incident"

    expect(page).not_to have_error_messages

    expect(page).to have_content "Incident: Teddy Bear"

    click_link "Back to allegation: #{investigation.pretty_id}"

    click_on "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

    expect(page).to have_selector("h1", text: "Activity")

    item = page.find("h3", text: "Incident").find(:xpath, "..")
    expect(item).to have_text("Date of incident: #{date.to_s(:govuk)}")
    expect(item).to have_text("Teddy Bear")
    expect(item).to have_text("Severity: Test")
    expect(item).to have_text("Product usage: During misuse")
  end

  scenario "Editing an accident, setting date to unknown, changing severity other" do
    sign_in(user)
    visit "/cases/#{investigation.pretty_id}"

    click_link "Supporting information (2)"

    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/supporting-information")

    click_link "During normal use: Teddy Bear"

    click_link "Edit accident"

    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/accident_or_incidents/#{accident.id}/edit")

    within_fieldset("Do you know when the accident happened?") do
      expect(page).to have_checked_field("Yes")
    end

    expect(page).to have_select("Select the product linked to this accident", selected: "Teddy Bear")

    within_fieldset("Indicate the severity") do
      expect(page).to have_checked_field("Other")
    end

    within_fieldset("How was the product being used at the time of this accident") do
      expect(page).to have_checked_field("During normal use")
    end

    choose("No")

    select "Doll", from: "Select the product linked to this accident"

    choose("Other")
    fill_in "Other type", with: "Test"

    choose("During misuse")

    fill_in("Additional information (optional)", with: "Some additional stuff you should know")

    click_button "Update accident"

    expect(page).not_to have_error_messages

    expect(page).to have_content "Accident: Doll"

    click_link "Back to allegation: #{investigation.pretty_id}"

    click_on "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

    expect(page).to have_selector("h1", text: "Activity")

    item = page.find("h3", text: "Accident").find(:xpath, "..")
    expect(item).to have_text("Date of accident: Unknown")
    expect(item).to have_text("Doll")
    expect(item).to have_text("Severity: Test")
    expect(item).to have_text("Product usage: During misuse")
  end
end
