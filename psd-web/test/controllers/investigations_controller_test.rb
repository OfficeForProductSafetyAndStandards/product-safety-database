require "test_helper"

class InvestigationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    allow(KeycloakClient.instance).to receive(:user_account_url).and_return("/account")

    user           = users(:opss)
    @non_opss_user = users(:southampton)

    allow(KeycloakClient.instance).
      to receive(:get_user_roles).with(@non_opss_user.id)
           .and_return([:psd_user])

    allow(KeycloakClient.instance).
      to receive(:get_user_roles).with(user.id)
           .and_return([:psd_user, :opss_user])
    stub_omniauth(user)
    sign_in user
    User.current = user
    allow_any_instance_of(NotifyMailer).to receive(:mail) { true }

    @investigation_one = load_case(:one)
    @investigation_one.created_at = Time.zone.parse("2014-07-11 21:00")
    @investigation_one.assignee = User.find_by(name: "Test User_four")
    @investigation_one.source = sources(:investigation_one)
    @investigation_one.save

    @investigation_two = load_case(:two)
    @investigation_two.created_at = Time.zone.parse("2015-07-11 21:00")
    @investigation_two.assignee = user
    @investigation_two.save

    @investigation_three = load_case(:three)
    @investigation_three.assignee = @non_opss_user
    @investigation_three.save

    @investigation_no_products = load_case(:no_products)
    @investigation_no_products.assignee = @non_opss_user
    @investigation_no_products.save

    # The updated_at values must be set separately in order to be respected
    @investigation_one.updated_at = Time.zone.parse("2017-07-11 21:00")
    @investigation_one.save
    @investigation_two.updated_at = Time.zone.parse("2016-07-11 21:00")
    @investigation_two.save

    Investigation.import refresh: true, force: true
  end

  test "should get index" do
    get investigations_url
    assert_response :success
  end

  test "should get new" do
    get new_investigation_url
    assert_response :success
  end

  test "should show investigation" do
    get investigation_url(@investigation_one)
    assert_response :success
  end

  test "should set status" do
    investigation = create_new_case
    is_closed = true
    investigation_status = lambda { Investigation.find(investigation.id).is_closed }
    assert_changes investigation_status, from: false, to: is_closed do
      patch status_investigation_url(investigation), params: {
              investigation: {
                is_closed: is_closed,
                status_rationale: "some rationale"
              }
            }
    end
    assert_redirected_to investigation_path(investigation)
  end

  test "should set description" do
    old_description = "old"
    new_description = "description"
    investigation = Investigation.create(description: old_description)
    investigation_status = lambda { Investigation.find(investigation.id).description }
    assert_changes investigation_status, from: old_description, to: new_description do
      patch edit_summary_investigation_url(investigation), params: {
              investigation: {
                description: new_description
              }
            }
    end
    assert_redirected_to investigation_path(investigation)
  end

  test "should require description to not be empty" do
    patch edit_summary_investigation_url(@investigation_one), params: {
            investigation: {
              description: ""
            }
          }, headers: { "HTTP_REFERER": "/cases/1111-1111/edit_summary" }
    assert_includes(CGI.unescapeHTML(response.body), "Description cannot be blank")
  end

  test "status filter should be defaulted to open" do
    get investigations_path
    assert_not_includes(response.body, @investigation_three.pretty_id)
    assert_includes(response.body, @investigation_one.pretty_id)

    assert_includes(response.body, @investigation_no_products.pretty_id)
  end

  test "status filter for both open and closed checked" do
    get investigations_path, params: {
          status_open: "checked",
          status_closed: "checked"
        }
    assert_includes(response.body, @investigation_one.pretty_id)
    assert_includes(response.body, @investigation_three.pretty_id)
    assert_includes(response.body, @investigation_no_products.pretty_id)
  end

  test "status filter for both open and closed unchecked" do
    get investigations_path, params: {
          status_open: "unchecked",
          status_closed: "unchecked"
        }
    assert_includes(response.body, @investigation_one.pretty_id)
    # assert_includes(response.body, @investigation_two.pretty_id)
    assert_includes(response.body, @investigation_three.pretty_id)
    assert_includes(response.body, @investigation_no_products.pretty_id)
  end

  test "status filter for only open checked" do
    get investigations_path, params: {
          status_open: "checked",
          status_closed: "unchecked"
        }
    assert_not_includes(response.body, @investigation_three.pretty_id)
    assert_includes(response.body, @investigation_one.pretty_id)
    # assert_includes(response.body, @investigation_two.pretty_id)
    assert_includes(response.body, @investigation_no_products.pretty_id)
  end

  test "status filter for only closed checked" do
    get investigations_path, params: {
      status_open: "unchecked",
      status_closed: "checked"
    }
    assert_includes(response.body, @investigation_three.pretty_id)
    assert_not_includes(response.body, @investigation_one.pretty_id)
    # assert_not_includes(response.body, @investigation_two.pretty_id)
    assert_not_includes(response.body, @investigation_no_products.pretty_id)
  end

  test "should return all investigations if all unchecked" do
    get investigations_path, params: {
        allegation: "unchecked",
        enquiry: "unchecked",
        project: "unchecked",
    }
    assert_includes(response.body, load_case(:allegation).pretty_id)
    assert_includes(response.body, load_case(:enquiry).pretty_id)
    assert_includes(response.body, load_case(:project).pretty_id)
  end

  test "should return all investigations if all checked" do
    get investigations_path, params: {
        allegation: "checked",
        enquiry: "checked",
        project: "checked",
    }
    assert_includes(response.body, load_case(:allegation).pretty_id)
    assert_includes(response.body, load_case(:enquiry).pretty_id)
    assert_includes(response.body, load_case(:project).pretty_id)
  end

  test "should return allegation investigations if allegation unchecked" do
    get investigations_path, params: {
        allegation: "checked",
        enquiry: "unchecked",
        project: "unchecked",
    }
    assert_includes(response.body, load_case(:allegation).pretty_id)
    assert_not_includes(response.body, load_case(:enquiry).pretty_id)
    assert_not_includes(response.body, load_case(:project).pretty_id)
  end

  test "should return all investigations if both assignee checkboxes are unchecked" do
    get investigations_path, params: {
        assigned_to_me: "unchecked",
        assigned_to_someone_else: "unchecked",
        status_open: "unchecked",
        status_closed: "unchecked"
    }
    assert_includes(response.body, @investigation_one.pretty_id)
    assert_includes(response.body, @investigation_two.pretty_id)
    assert_includes(response.body, @investigation_three.pretty_id)
  end

  test "should return all investigations if both assignee checkboxes are checked and name input is blank" do
    get investigations_path, params: {
        assigned_to_me: "checked",
        assigned_to_someone_else: "checked",
        assigned_to_someone_else_id: nil,
        status_open: "unchecked",
        status_closed: "unchecked"
    }
    assert_includes(response.body, @investigation_one.pretty_id)
    assert_includes(response.body, @investigation_two.pretty_id)
    assert_includes(response.body, @investigation_three.pretty_id)
  end

  test "should return investigations assigned to current user if only the 'Me' checkbox is checked" do
    get investigations_path, params: {
        assigned_to_me: "checked",
        assigned_to_someone_else: "unchecked",
        assigned_to_someone_else_id: nil,
        assigned_to_team_0: "unchecked",
        status_open: "unchecked",
        status_closed: "unchecked"
    }
    assert_includes(response.body, @investigation_one.pretty_id)
    assert_not_includes(response.body, @investigation_two.pretty_id)
    assert_not_includes(response.body, @investigation_three.pretty_id)
  end

  test "should return investigations assigned to current user or given user if both checkboxes are checked
              and a user is given in the input" do
    get investigations_path, params: {
        assigned_to_me: "checked",
        assigned_to_someone_else: "checked",
        assigned_to_someone_else_id: @investigation_two.assignable_id,
        status_open: "unchecked",
        status_closed: "unchecked"
    }
    assert_includes(response.body, @investigation_one.pretty_id)
    assert_includes(response.body, @investigation_two.pretty_id)
    assert_not_includes(response.body, @investigation_three.pretty_id)
  end

  test "should return investigations assigned to a given user if only 'someone else' checkbox is checked
              and a user is given in the input" do
    get investigations_path, params: {
        assigned_to_me: "unchecked",
        assigned_to_someone_else: "checked",
        assigned_to_someone_else_id: @investigation_two.assignable_id,
        assigned_to_team_0: "unchecked",
        status_open: "unchecked",
        status_closed: "unchecked"
    }
    assert_not_includes(response.body, @investigation_one.pretty_id)
    assert_includes(response.body, @investigation_two.pretty_id)
    assert_not_includes(response.body, @investigation_three.pretty_id)
  end

  test "should return investigations assigned to anyone except current user if only 'someone else' checkbox
              is checked and no user is given in the input" do
    get investigations_path, params: {
        assigned_to_me: "unchecked",
        assigned_to_someone_else: "checked",
        assigned_to_someone_else_id: nil,
        status_open: "unchecked",
        status_closed: "unchecked"
    }
    assert_not_includes(response.body, @investigation_one.pretty_id)
    assert_includes(response.body, @investigation_two.pretty_id)
    assert_includes(response.body, @investigation_three.pretty_id)
  end

  test "sort by filter should be defaulted to 'Most recently updated'" do
    get investigations_path
    # assert response.body.index(@investigation_one.pretty_id.to_s) < response.body.index(@investigation_two.pretty_id.to_s)
  end

  test "should return the most recently updated investigation first if sort by 'Most recently updated' is selected" do
    get investigations_path, params: {
        status_open: "unchecked",
        status_closed: "unchecked",
        sort_by: "recent"
    }
    # assert response.body.index(@investigation_one.pretty_id.to_s) < response.body.index(@investigation_two.pretty_id.to_s)
  end

  test "should return the oldest updated investigation first if sort by 'Least recently updated' is selected" do
    get investigations_path, params: {
        status_open: "unchecked",
        status_closed: "unchecked",
        sort_by: "oldest"
    }
    # assert response.body.index(@investigation_two.pretty_id.to_s) < response.body.index(@investigation_one.pretty_id.to_s)
  end

  test "should return the most recently created investigation first if sort by 'Most recently created' is selected" do
    get investigations_path, params: {
        status_open: "unchecked",
        status_closed: "unchecked",
        sort_by: "newest"
    }
    # assert response.body.index(@investigation_two.pretty_id.to_s) < response.body.index(@investigation_one.pretty_id.to_s)
  end

  test "should create excel file for list of investigations" do
    get investigations_path format: :xlsx
    assert_response :success
  end

  test "should not show private investigations to everyone" do
    create_new_private_case
    sign_out(:user)
    sign_in @non_opss_user

    get investigations_path
    assert_includes(response.body, "restricted")
  end

  test "should not show case to someone without access" do
    create_new_private_case
    sign_out :user
    sign_in @non_opss_user

    assert_raise(Pundit::NotAuthorizedError) {
      get investigation_path(@new_investigation)
    }
  end

  test "should show private investigations to creator" do
    create_new_private_case

    get investigation_path(@new_investigation)
    assert_includes(response.body, @new_investigation.pretty_id)
  end

  def create_new_private_case
    description = "new_investigation_description"
    Investigation::Allegation.create(description: description)
    patch visibility_investigation_url(Investigation.find_by(description: description)), params: {
      investigation: {
        is_private: true
      }
    }
    @new_investigation = Investigation.find_by(description: description)
  end
end
