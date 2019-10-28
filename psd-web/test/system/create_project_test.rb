require "application_system_test_case"

class CreateProjectTest < ApplicationSystemTestCase
  setup do
    @project = Investigation::Project.new(description: "new project description", user_title: "project title")
    mock_out_keycloak_and_notify
    visit new_project_path
  end

  teardown do
    reset_keycloak_and_notify_mocks
  end

  test "can be reached via create page" do
    visit root_path
    click_on "Create new"
    assert_text "Create new"

    choose "type_project", visible: false
    click_on "Continue"

    assert_text "New project"
  end

  test "first step should be allegation details" do
    assert_text "New project"
    assert_text "Please provide a title"
    assert_text "Project summary"
  end

  test "first step should require a description" do
    click_on "Create project"
    assert_text "Description can't be blank"
  end

  test "third step should require title" do
    click_on "Create project"
    assert_text "User title can't be blank"
  end

  test "project details should show in overview" do
    fill_project_details_and_continue

    project = Investigation::Project.find_by(user_title: @project.user_title)

    assert_css ".hmcts-banner--success", text: "Project was successfully created"
    assert_css "h1.govuk-heading-l span.govuk-caption-l", text: project.pretty_description
    assert_css "dt.govuk-summary-list__key", text: "Product category"
    assert_no_css "h3.govuk-heading-s", text: "Reporter"

    complaint = complainants(:one)
    complaint.complainant_type = "Some Complaint Type"

    project.update!(complainant: complaint)

    visit investigation_path(project)

    assert_css "h3.govuk-heading-s", text: "Reporter"
  end

  def fill_project_details_and_continue
    fill_in "investigation[description]", with: @project.description
    fill_in "investigation[user_title]", with: @project.user_title
    click_on "Create project"
  end
end
