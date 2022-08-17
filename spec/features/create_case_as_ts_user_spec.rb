require "rails_helper"

RSpec.feature "Creating a case as a TS user", :with_stubbed_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated) }
  let(:investigation_with_same_user_title) do
    create(:allegation,
           creator: user,
           user_title: "title1")
  end

  scenario "Opening a new case (with validation error)" do
    sign_in(user)

    click_link "Create a case"

    expect(page).to have_css("h1", text: "Why are you creating a case?")

    click_button "Continue"

    expect(errors_list[0].text).to eq "Select a product is of concern if the product might be unsafe or non-compliant"

    within_fieldset("Why are you creating a case?") do
      choose("A product is of concern")
    end

    click_button "Continue"

    expect(page).to have_css("h1", text: "Why is the product of concern?")

    click_button "Continue"

    expect(errors_list[0].text).to eq "Select the options which are reasons for concern"

    within_fieldset("Why is the product of concern?") do
      check "The product is unsafe (or suspected of being)"
      check "The product is non-compliant (or suspected of being)"
    end

    click_button "Continue"

    expect(errors_list[0].text).to eq "Select the primary hazard"
    expect(errors_list[1].text).to eq "Enter why the product is unsafe"
    expect(errors_list[2].text).to eq "Enter why the product is non-compliant"

    within_fieldset("Why is the product of concern?") do
      check "The product is unsafe (or suspected of being)"
      check "The product is non-compliant (or suspected of being)"
    end

    select "Burns", from: "hazard_type"
    fill_in "Why is the product unsafe?", with: "It's too hot"
    fill_in "Why is the product non-compliant?", with: "does not comply with laws"

    click_button "Continue"

    expect(page).to have_css("h1", text: "Do you want to add a reference number?")

    click_button "Continue"

    expect(errors_list[0].text).to eq "Select yes to add a reference number to the case"

    within_fieldset("Do you want to add a reference number?") do
      choose("Yes")
    end

    click_button "Continue"

    expect(errors_list[0].text).to eq "Enter a reference number"

    fill_in "Reference number", with: "12345"

    click_button "Continue"

    expect(page).to have_css("h1", text: "What is the case name?")

    click_button "Continue"

    expect(errors_list[0].text).to eq "Enter a case name"

    find("#user_title").set(investigation_with_same_user_title.user_title)
    click_button "Continue"

    expect(errors_list[0].text).to eq "The case name has already been used in an open case by your team"

    find("#user_title").set("Some other title")

    click_button "Continue"

    expect(page).to have_css("h1", text: "Case created")
    expect(page).to have_content("Case number#{Investigation.last.pretty_id}")

    click_link "View the case"

    expect(page).to have_current_path("/cases/#{Investigation.last.pretty_id}")

    expect(page.find("dt", text: "Reported as")).to have_sibling("dd", text: "Unsafe and non-compliant")
    expect(page.find("dt", text: "Primary hazard")).to have_sibling("dd", text: "Burns")
    expect(page.find("dt", text: "Hazard description")).to have_sibling("dd", text: "It's too hot")
    expect(page.find("dt", text: "Compliance")).to have_sibling("dd", text: "does not comply with laws")
  end

  context "when a case is safe and compliant" do
    it "does not take user to the safety and compliance details page" do
      sign_in(user)

      click_link "Create a case"

      expect(page).to have_css("h1", text: "Why are you creating a case?")

      click_button "Continue"

      expect(errors_list[0].text).to eq "Select a product is of concern if the product might be unsafe or non-compliant"

      within_fieldset("Why are you creating a case?") do
        choose("A product is safe and compliant")
      end

      click_button "Continue"

      expect(page).to have_css("h1", text: "Do you want to add a reference number?")
    end
  end

  context "when a user tries to navigate to a page outside of the wizard order" do
    it "does not take user to the safety and compliance details page" do
      sign_in(user)

      visit "/ts_investigation/case_name"

      expect(page).not_to have_css("h1", text: "What is the case name?")
      expect(page).to have_no_current_path "ts_investigation/case_name"

      expect(page).to have_css("h1", text: "Why are you creating a case?")
      expect(page).to have_no_current_path "ts_investigation/reason_for_creating"
    end
  end

  def errors_list
    page.find(".govuk-error-summary__list").all("li")
  end
end
