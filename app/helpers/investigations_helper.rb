module InvestigationsHelper
  include SearchHelper

  def search_for_investigations(page_size = Investigation.count)
    query  = ElasticsearchQuery.new(@search.q, filter_params, @search.sorting_params, nested: nested_filters)
    result = Investigation.full_search(query)
    result.paginate(page: params[:page], per_page: page_size)
  end

  def set_search_params
    params_to_save = params.dup
    params_to_save.delete(:sort_by) if params[:sort_by] == SearchParams::RELEVANT
    @search = SearchParams.new(query_params.except(:case_owner_is_team_0, :created_by_team_0))

    store_previous_search_params
  end

  def filter_params
    filters = {}
    filters.merge!(get_type_filter)
    filters.merge!(merged_must_filters) { |_key, current_filters, new_filters| current_filters + new_filters }
  end

  def nested_filters
    filters = []

    if @search.filter_teams_with_access?
      filters << {
        nested: {
          path: :teams_with_access,
          query: { bool: { must: { terms: { "teams_with_access.id" => @search.teams_with_access_ids } } } }
        }
      }
    end

    filters
  end

  def merged_must_filters
    must_filters = {
      must: [
        get_status_filter,
        { bool: get_creator_filter },
        { bool: get_owner_filter }
      ]
    }

    if params[:coronavirus_related_only] == "yes"
      must_filters[:must] << { term: { coronavirus_related: true } }
    end

    if params[:serious_and_high_risk_level_only] == "yes"
      must_filters[:must] << { terms: { risk_level: Investigation.risk_levels.values_at(:serious, :high) } }
    end

    must_filters
  end

  def get_status_filter
    return unless @search.filter_status?

    status = if @search.status_open?
               { is_closed: false }
             else
               { is_closed: true }
             end
    { term: status }
  end

  def get_type_filter
    return {} if params[:allegation] == "unchecked" && params[:enquiry] == "unchecked" && params[:project] == "unchecked"

    types = []
    types << "Investigation::Allegation" if params[:allegation] == "checked"
    types << "Investigation::Enquiry" if params[:enquiry] == "checked"
    types << "Investigation::Project" if params[:project] == "checked"
    type = { type: types }
    { must: [{ terms: type }] }
  end

  def get_owner_filter
    return { should: [], must_not: [] } if no_owner_boxes_checked
    return { should: [], must_not: compute_excluded_terms } if owner_filter_exclusive

    { should: compute_included_terms, must_not: [] }
  end

  def no_owner_boxes_checked
    no_people_boxes_checked = params[:case_owner_is_me] == "unchecked" && params[:case_owner_is_someone_else] == "unchecked"
    no_team_boxes_checked = query_params[owner_team_with_key[0]].blank?
    no_people_boxes_checked && no_team_boxes_checked
  end

  def owner_filter_exclusive
    params[:case_owner_is_someone_else] == "checked" && params[:case_owner_is_someone_else_id].blank?
  end

  def compute_excluded_terms
    # After consultation with designers we chose to ignore teams who are not selected in blacklisting
    excluded_owners = []
    excluded_owners << current_user.id if params[:case_owner_is_me] == "unchecked"
    format_owner_terms(excluded_owners)
  end

  def compute_included_terms
    # If 'Me' is not checked, but one of current users teams is selected, we don't exclude current user from it
    owners = checked_team_owners
    owners.concat(someone_else_owners)
    owners << current_user.id if params[:case_owner_is_me] == "checked"
    format_owner_terms(owners.uniq)
  end

  def checked_team_owners
    owners = []
    owners.concat(user_ids_from_team(owner_team_with_key[1])) if query_params[owner_team_with_key[0]] != "unchecked"
    owners
  end

  def someone_else_owners
    return [] unless params[:case_owner_is_someone_else] == "checked"

    team = Team.find_by(id: params[:case_owner_is_someone_else_id])
    team.present? ? user_ids_from_team(team) : [params[:case_owner_is_someone_else_id]]
  end

  def format_owner_terms(owner_array)
    owner_array.map do |a|
      { term: { owner_id: a } }
    end
  end

  def get_creator_filter
    return { should: [], must_not: [] } if no_created_by_boxes_checked
    return { should: [], must_not: compute_excluded_created_by_terms } if creator_filter_exclusive

    { should: compute_included_created_by_terms, must_not: [] }
  end

  def no_created_by_boxes_checked
    no_created_by_people_boxes_checked = params[:created_by_me] == "unchecked" && params[:created_by_someone_else] == "unchecked"
    no_created_by_team_boxes_checked = query_params[creator_team_with_key[0]] == "unchecked"
    no_created_by_people_boxes_checked && no_created_by_team_boxes_checked
  end

  def creator_filter_exclusive
    params[:created_by_someone_else] == "checked" && params[:created_by_someone_else_id].blank?
  end

  def compute_excluded_created_by_terms
    # After consultation with designers we chose to ignore teams who are not selected in blacklisting
    excluded_creators = []
    excluded_creators << current_user.id if params[:created_by_me] == "unchecked"
    format_creator_terms(excluded_creators)
  end

  def compute_included_created_by_terms
    # If 'Me' is not checked, but one of current users teams is selected, we don't exclude current user from it
    creators = checked_team_creators
    creators.concat(someone_else_creators)
    creators << current_user.id if params[:created_by_me] == "checked"
    format_creator_terms(creators.uniq)
  end

  def checked_team_creators
    creators = []
    creators.concat(user_ids_from_team(creator_team_with_key[1])) if query_params[creator_team_with_key[1]] != "unchecked"
    creators
  end

  def someone_else_creators
    return [] unless params[:created_by_someone_else] == "checked"

    team = Team.find_by(id: params[:created_by_someone_else_id])
    team.present? ? user_ids_from_team(team) : [params[:created_by_someone_else_id]]
  end

  def format_creator_terms(creator_array)
    creator_array.map do |a|
      { term: { creator_id: a } }
    end
  end

  def creator_team_with_key
    [
      "created_by_team_0".to_sym,
      current_user.team,
      "My team"
    ]
  end

  def query_params
    set_default_type_filter
    set_default_creator_filter
    params.permit(
      :q,
      :status_open,
      :status_closed,
      :page,
      :allegation,
      :enquiry,
      :project,
      :case_owner_is_me,
      :case_owner_is_someone_else,
      :case_owner_is_someone_else_id,
      :sort_by,
      :created_by_me,
      :created_by_me,
      :created_by_someone_else,
      :created_by_someone_else_id,
      :coronavirus_related_only,
      :serious_and_high_risk_level_only,
      owner_team_with_key[0],
      creator_team_with_key[0],
      teams_with_access: { id: [] }
    )
  end

  def export_params
    query_params.except(:page)
  end

  def set_default_creator_filter
    params[:created_by_me] = "unchecked" if params[:created_by_me].blank?
    params[:created_by_team_0] = "unchecked" if params[:created_by_team_0].blank?
    params[:created_by_someone_else] = "unchecked" if params[:created_by_someone_else].blank?
  end

  def set_default_type_filter
    params[:allegation] = "unchecked" if params[:allegation].blank?
    params[:enquiry] = "unchecked" if params[:enquiry].blank?
    params[:project] = "unchecked" if params[:project].blank?
  end

  def build_breadcrumb_structure
    {
      items: [
        {
          text: "Cases",
          href: investigations_path(previous_search_params)
        },
        {
          text: @investigation.pretty_description
        }
      ]
    }
  end

  def owner_team_with_key
    [
      "case_owner_is_team_0".to_sym,
      current_user.team,
      "My team"
    ]
  end

  def user_ids_from_team(team)
    [team.id] + team.users.map(&:id)
  end

  def risks_and_issues_rows(investigation, user)
    risk_level_row = {
      key: {
        text: t(:key, scope: "investigations.overview.case_risk_level")
      },
      value: { text: investigation.risk_level_description }
    }

    if policy(investigation).update?(user: user)
      risk_level_row[:actions] = { items: [
                                     href: investigation_risk_level_path(investigation),
                                     text: t(
                                       (investigation.risk_level ? :change : :set),
                                       scope: "investigations.overview.case_risk_level.action"
                                     ),
                                     visuallyHiddenText: t(:visually_hidden_text, scope: "investigations.overview.case_risk_level")
                                   ] }
    end

    most_recent_risk_assessment = investigation.risk_assessments.max_by(&:assessed_on)

    risk_assessment_row = {
      key: {
        text: t(:key,
                scope: "investigations.overview.risk_assessments",
                count: investigation.risk_assessments.count)
      },
      value: {
        text: t(:value_html,
                scope: "investigations.overview.risk_assessments",
                count: investigation.risk_assessments.count,
                assessed_by: (most_recent_risk_assessment ? risk_assessed_by(team: most_recent_risk_assessment.assessed_by_team, business: most_recent_risk_assessment.assessed_by_business, other: most_recent_risk_assessment.assessed_by_other) : ""),
                assessed_on: (most_recent_risk_assessment ? most_recent_risk_assessment.assessed_on.to_s(:govuk) : ""),
                assessed_risk: (most_recent_risk_assessment ? most_recent_risk_assessment.risk_level_description : ""))
      }
    }

    if policy(investigation).update?(user: user) || most_recent_risk_assessment

      risk_assessment_href =
        case investigation.risk_assessments.count
        when 0
          new_investigation_risk_assessment_path(investigation.pretty_id)
        when 1
          investigation_risk_assessment_path(investigation.pretty_id, most_recent_risk_assessment.id)
        else
          investigation_supporting_information_index_path(investigation.pretty_id)
        end

      risk_assessment_row[:actions] = {
        items: [
          {
            text: t(:action, scope: "investigations.overview.risk_assessments", count: investigation.risk_assessments.count),
            visuallyHiddenText: t(:visually_hidden_text, scope: "investigations.overview.risk_assessments", count: investigation.risk_assessments.count),
            href: risk_assessment_href
          }
        ]
      }
    end

    risk_validated_value = if investigation.risk_validated_by
                             t("investigations.risk_validation.validated_status", risk_validated_by: investigation.risk_validated_by, risk_validated_at: investigation.risk_validated_at.strftime("%d %B %Y"))
                           else
                             t("investigations.risk_validation.not_validated")
                           end

    validated_row = {
      key: { text: t("investigations.risk_validation.page_title") },
      value: { text: risk_validated_value },
      actions: risk_validation_actions(investigation, user)
    }

    rows = [risk_level_row, validated_row, risk_assessment_row]

    if investigation.hazard_type.present?
      rows << {
        key: { text: t(:key, scope: "investigations.overview.hazards") },
        value: { text: simple_format([investigation.hazard_type, investigation.hazard_description].join("\n\n")) }
      }
    end

    if investigation.non_compliant_reason.present?
      rows << {
        key: { text: t(:key, scope: "investigations.overview.compliance") },
        value: { text: simple_format(investigation.non_compliant_reason) }
      }
    end

    rows
  end

  def risk_validation_actions(investigation, user)
    if policy(Investigation).risk_level_validation? && investigation.teams_with_access.include?(user.team)
      {
        items: [
          href: edit_investigation_risk_validations_path(investigation.pretty_id),
          text: risk_validated_link_text(investigation)
        ]
      }
    else
      {}
    end
  end

  def risk_validated_link_text(investigation)
    investigation.risk_validated_by ? "Change" : t("investigations.risk_validation.validate")
  end

  # This builds an array from an investigation which can then
  # be passed as a `rows` argument to the govukSummaryList() helper.
  def about_the_case_rows(investigation, user)
    coronavirus_related_actions = { items: [] }
    status_actions = { items: [] }
    activity_actions = { items: [] }

    if policy(investigation).update?(user: user)
      activity_actions[:items] << {
        href: new_investigation_supporting_information_path(investigation),
        text: "Add supporting information"
      }
      coronavirus_related_actions[:items] << {
        href: investigation_coronavirus_related_path(investigation),
        text: "Change",
        visuallyHiddenText: "coronavirus status"
      }
    end

    if policy(investigation).change_owner_or_status?(user: user)
      status_actions[:items] << {
        href: status_investigation_path(investigation),
        text: "Change",
        visuallyHiddenText: "status"
      }
    end

    rows = [
      {
        key: { text: "Status" },
        value: { text: investigation.status },
        actions: status_actions
      },
      {
        key: { text: "Coronavirus related" },
        value: { text: I18n.t(investigation.coronavirus_related, scope: "case.coronavirus_related") },
        actions: coronavirus_related_actions
      },
      {
        key: { text: "Created by" },
        value: { text: investigation.created_by }
      },
      {
        key: { text: "Date created" },
        value: { text: investigation.created_at.to_s(:govuk) }
      },
      {
        key: { text: "Last updated" },
        value: { text: "#{time_ago_in_words(investigation.updated_at)} ago" },
        actions: activity_actions
      }
    ]

    if investigation.complainant_reference.present?
      rows << {
        key: { text: "Trading Standards reference" },
        value: { text: investigation.complainant_reference }
      }
    end

    rows
  end

  def add_new_menu_data_attributes(investigation)
    supporting_information_types = [
      {
        path: new_investigation_activity_comment_path(investigation),
        text: "Comment"
      },
      {
        path: new_investigation_corrective_action_path(investigation),
        text: "Corrective action"
      },
      {
        path: new_investigation_correspondence_path(investigation),
        text: "Correspondence"
      },
      {
        path: new_investigation_new_path(investigation),
        text: "Image"
      },
      {
        path: new_investigation_test_result_path(investigation),
        text: "Test result"
      },
      {
        path: new_investigation_risk_assessment_path(investigation),
        text: "Risk assessment"
      },
      {
        path: new_investigation_accident_or_incidents_type_path(investigation),
        text: "Accident or incident"
      },
      {
        path: new_investigation_new_path(investigation),
        text: "Other document or attachment"
      }

    ]

    data_attributes = {}

    supporting_information_types.each_with_index do |supporting_information_type, index|
      data_attributes["item-#{index + 1}-text"] = supporting_information_type[:text]
      data_attributes["item-#{index + 1}-href"] = supporting_information_type[:path]
    end

    data_attributes
  end

  def actions_menu_data_attributes(investigation)
    actions = []

    if policy(investigation).change_owner_or_status?

      case_status = investigation.is_closed? ? "closed" : "open"
      visibility_status = investigation.is_private? ? "restricted" : "not_restricted"

      actions << {
        path: status_investigation_path(@investigation),
        text: I18n.t("change_case_status.#{case_status}", scope: "forms.investigation_actions.actions")
      }

      actions << {
        path: new_investigation_ownership_path(@investigation),
        text: I18n.t(:change_case_owner, scope: "forms.investigation_actions.actions")
      }

      actions << {
        path: visibility_investigation_path(@investigation),
        text: I18n.t("change_case_visibility.#{visibility_status}", scope: "forms.investigation_actions.actions")
      }
    end

    if policy(investigation).send_email_alert?

      actions << {
        path: new_investigation_alert_path(@investigation),
        text: I18n.t(:send_email_alert, scope: "forms.investigation_actions.actions")
      }
    end

    data_attributes = {}

    actions.each_with_index do |supporting_information_type, index|
      data_attributes["item-#{index + 1}-text"] = supporting_information_type[:text]
      data_attributes["item-#{index + 1}-href"] = supporting_information_type[:path]
    end

    data_attributes
  end

  def store_previous_search_params
    session[:previous_search_params] = @search.serializable_hash(form_serialisation_option).symbolize_keys
  end

  def form_serialisation_option
    options = { include: :teams_with_access }
    options[:except] = :sort_by if params[:sort_by] == SearchParams::RELEVANT

    options
  end
end
