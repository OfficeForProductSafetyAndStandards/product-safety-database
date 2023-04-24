require "rails_helper"

RSpec.feature "Editing an accident or incident on a case", :with_stubbed_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated, name: "Joe Bloggs") }
  let(:teddy_bear) { create(:product, name: "Teddy Bear") }
  let(:doll) { create(:product, name: "Doll") }
  let(:date) { Date.current }
  let(:team) { create(:team, name: "MyCouncil Trading Standards") }

  let!(:doll_investigation_product)       { create(:investigation_product, investigation:, product: doll) }
  let!(:teddy_bear_investigation_product) { create(:investigation_product, investigation:, product: teddy_bear) }

  let(:investigation) do
    create(:allegation,
           creator: user,
           risk_level: :serious)
  end
  let!(:incident) do
    create(:incident,
           date: nil,
           is_date_known: false,
           investigation_product: doll_investigation_product,
           severity: "serious",
           usage: "during_normal_use",
           investigation:)
  end

  let!(:accident) do
    create(:accident,
           date: Date.current,
           is_date_known: true,
           investigation_product: teddy_bear_investigation_product,
           severity: "other",
           severity_other: "very extreme",
           usage: "during_normal_use",
           investigation:)
  end

  scenario "Editing an incident, setting date to known, (with validation errors)" do
    sign_in(user)
    visit "/cases/#{investigation.pretty_id}"

    click_link "Supporting information (2)"

    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/supporting-information")

    click_link "Doll #{doll.psd_ref}: Normal use"

    click_link "Edit incident"

    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/accident_or_incidents/#{incident.id}/edit")

    within_fieldset("Do you know when the incident happened?") do
      expect(page).to have_checked_field("No")
    end

    expect(page).to have_select("Which product was involved?", selected: "Doll (#{doll.psd_ref})")

    within_fieldset("Indicate the severity") do
      expect(page).to have_checked_field("Serious")
    end

    within_fieldset("How was the product being used?") do
      expect(page).to have_checked_field("Normal use")
    end

    choose("Yes")
    fill_in("Day", with: date.day)
    fill_in("Month", with: date.month)
    fill_in("Year", with: date.year)

    select "Teddy Bear", from: "Which product was involved?"

    choose("Other")
    fill_in "Other type", with: "Test"

    choose("Misuse")

    fill_in("Additional information (optional)", with: "Some additional stuff you should know")

    click_button "Update incident"

    expect(page).not_to have_error_messages

    click_link "Teddy Bear #{teddy_bear.psd_ref}: Misuse"

    expect(page).to have_content "Incident involving Teddy Bear"

    click_link "Back to case: #{investigation.pretty_id}"

    click_on "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

    expect(page).to have_selector("h1", text: "Activity")

    item = page.find("h3", text: "Incident").find(:xpath, "..")
    expect(item).to have_text("Date of incident: #{date.to_formatted_s(:govuk)}")
    expect(item).to have_text("Teddy Bear")
    expect(item).to have_text("Severity: Test")
    expect(item).to have_text("Product usage: Misuse")
  end

  scenario "Editing an accident, setting date to unknown, changing severity other" do
    sign_in(user)
    visit "/cases/#{investigation.pretty_id}"

    click_link "Supporting information (2)"

    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/supporting-information")

    click_link "Teddy Bear #{teddy_bear.psd_ref}: Normal use"

    click_link "Edit accident"

    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/accident_or_incidents/#{accident.id}/edit")

    within_fieldset("Do you know when the accident happened?") do
      expect(page).to have_checked_field("Yes")
    end

    expect(page).to have_select("Which product was involved?", selected: "Teddy Bear (#{teddy_bear.psd_ref})")

    within_fieldset("Indicate the severity") do
      expect(page).to have_checked_field("Other")
    end

    within_fieldset("How was the product being used?") do
      expect(page).to have_checked_field("Normal use")
    end

    choose("No")

    select "Doll", from: "Which product was involved?"

    choose("Other")
    fill_in "Other type", with: "Test"

    choose("Misuse")

    fill_in("Additional information (optional)", with: "Some additional stuff you should know")

    click_button "Update accident"

    click_link "Doll #{doll.psd_ref}: Misuse"

    expect(page).not_to have_error_messages

    expect(page).to have_content "Accident involving Doll"

    click_link "Back to case: #{investigation.pretty_id}"

    click_on "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

    expect(page).to have_selector("h1", text: "Activity")

    item = page.find("h3", text: "Accident").find(:xpath, "..")
    expect(item).to have_text("Date of accident: Unknown")
    expect(item).to have_text("Doll")
    expect(item).to have_text("Severity: Test")
    expect(item).to have_text("Product usage: Misuse")
  end
end
