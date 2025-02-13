module InvestigationsHelper
  HAZARD_TYPES = Rails.application.config.hazard_constants["hazard_type"]
  HAZARD_PARAMS = HAZARD_TYPES.map { |type| type.parameterize.underscore.to_sym }
  CASE_TYPES = %i[allegation enquiry project notification].freeze
  REPORTED_REASONS = %i[safe_and_compliant unsafe_and_non_compliant unsafe non_compliant].freeze

  def new_opensearch_for_investigations(page_size = Investigation.count, user = current_user, scroll: false, paginate: false)
    # Opensearch is only used for searching across all investigations
    @search.q.strip! if @search.q
    query = @search.q.presence || "*"

    wheres = {}

    wheres[:deleted_at] = nil

    case_types =  if user.is_opss?
                    CASE_TYPES.map { |type| "Investigation::#{type.capitalize}" if @search.send(type) }.compact
                  else
                    ["Investigation::Notification"]
                  end
    wheres[:type] = case_types unless case_types.empty?

    risk_levels = []

    %i[serious high medium low].each do |risk_level|
      risk_levels << risk_level if @search.send(risk_level)
    end

    risk_levels << nil if @search.not_set

    wheres[:risk_level] = risk_levels unless risk_levels.empty?

    hazard_types = HAZARD_TYPES.map { |type| type if @search.send(type.parameterize.underscore.to_sym) }.compact

    wheres[:hazard_type] = hazard_types unless hazard_types.empty?

    unless @search.case_status_open && @search.case_status_closed
      wheres[:is_closed] = false if @search.case_status_open
      wheres[:is_closed] = true if @search.case_status_closed
    end

    creator_ids = []
    creator_team_ids = []

    creator_ids << user.id if @search.created_by_me

    if @search.created_by_my_team
      team = user.team

      creator_ids += team.users.pluck(:id)
      creator_team_ids << team.id
    end

    if @search.created_by_others && @search.created_by_other_id.present?
      if (team = Team.find_by(id: @search.created_by_other_id))
        creator_ids += team.users.pluck(:id)
        creator_team_ids << team.id
      else
        creator_ids << @search.created_by_other_id
      end
    end

    if creator_ids.empty? && creator_team_ids.empty?
      if @search.created_by_others
        wheres[:_not] = { creator_user: user.team.user_ids }
      end
    else
      unless @search.created_by_others && @search.created_by_other_id.blank?
        wheres[:_or] = [
          { creator_user: creator_ids },
          { creator_team: creator_team_ids }
        ]
      end
    end

    case_owner_ids = []

    case_owner_ids << user.id if @search.case_owner_me

    if @search.case_owner_my_team
      team = user.team
      case_owner_ids += team.users.pluck(:id)
    end

    if @search.case_owner_other && @search.case_owner_is_someone_else_id.present?
      if (team = Team.find_by(id: @search.case_owner_is_someone_else_id))
        case_owner_ids += team.users.pluck(:id)
      else
        case_owner_ids << @search.case_owner_is_someone_else_id
      end
    end

    if case_owner_ids.empty?
      wheres[:_not] ||= {}
      wheres[:_not][:owner_id] = user.team.user_ids if @search.case_owner_other
    else
      unless @search.case_owner_other && @search.case_owner_is_someone_else_id.blank?
        wheres[:_or] ||= []
        wheres[:_or] += [
          { owner_id: case_owner_ids }
        ]
      end
    end

    team_ids_with_access = []
    team_ids_with_access << user.team.id if @search.teams_with_access_my_team
    team_ids_with_access << @search.teams_with_access_other_id if @search.teams_with_access_others && @search.teams_with_access_other_id.present?

    wheres[:team_ids_with_access] = team_ids_with_access if @search.teams_with_access_my_team || @search.teams_with_access_others

    if @search.created_from_date.present? && @search.created_to_date.present?
      wheres[:created_at] = { gte: @search.created_from_date.at_midnight, lte: @search.created_to_date.at_end_of_day }
    elsif @search.created_from_date.present?
      wheres[:created_at] = { gte: @search.created_from_date.at_midnight }
    elsif @search.created_to_date.present?
      wheres[:created_at] = { lte: @search.created_to_date.at_midnight }
    end

    reported_reasons = REPORTED_REASONS.map { |reason| reason.to_s if @search.send(reason) }.compact
    wheres[:reported_reason] = reported_reasons unless reported_reasons.empty?

    if paginate
      Investigation.pagy_search(
        query,
        where: wheres,
        order: @search.sorting_params,
        misspellings: { edit_distance: searching_for_investigation_pretty_id?(query) ? 0 : 2 },
        page: page_number,
        per_page: page_size,
        body_options: { track_total_hits: true },
        scroll: scroll_time(scroll)
      )
    else
      Investigation.search(
        query,
        where: wheres,
        order: @search.sorting_params,
        misspellings: { edit_distance: searching_for_investigation_pretty_id?(query) ? 0 : 2 },
        page: page_number,
        per_page: page_size,
        body_options: { track_total_hits: true },
        scroll: scroll_time(scroll)
      )
    end
  end

  def search_for_investigations(user = current_user, ids_only: false, page_param: :page)
    query = Investigation.not_deleted.includes(:owner_user, :owner_team, :creator_user, :creator_team, :collaboration_accesses, :activities)

    if @search.q.present?
      @search.q.strip!
      query = query.where("description ILIKE ?", "%#{@search.q}%")
        .or(Investigation.where(pretty_id: @search.q))
    end

    case @search.case_type
    when "allegation"
      query = query.where(type: "Investigation::Allegation")
    when "project"
      query = query.where(type: "Investigation::Project")
    when "notification"
      query = query.where(type: "Investigation::Notification")
    when "enquiry"
      query = query.where(type: "Investigation::Enquiry")
    end

    if @search.priority == "serious_and_high_risk_level_only"
      query = query.where(risk_level: %i[serious high])
    end

    if @search.hazard_type.present?
      query = query.where(hazard_type: @search.hazard_type)
    end

    case @search.case_status
    when "open"
      query = query.where(is_closed: false)
    when "closed"
      query = query.where(is_closed: true)
    end

    case @search.created_by
    when "me"
      query = query.where(creator_users_investigations: { id: user.id })
    when "my_team"
      team = user.team
      query = query.where(creator_users_investigations: { id: team.users.map(&:id) }, creator_teams_investigations: { id: team.id })
    when "others"
      query = if @search.created_by_other_id.blank?
                query.where.not(creator_users_investigations: { id: user.team.user_ids })
              elsif (team = Team.find_by(id: @search.created_by_other_id))
                query.where(creator_users_investigations: { id: team.users.map(&:id) }, creator_teams_investigations: { id: team.id })
              else
                query.where(creator_users_investigations: { id: @search.created_by_other_id })
              end
    end

    case @search.case_owner
    when "me"
      query = query.where(users: { id: user.id })
    when "my_team"
      team = user.team
      query = query.where(users: { id: team.users.map(&:id) }, teams: { id: team.id })
    when "others"
      query = if (team = Team.find_by(id: @search.case_owner_is_someone_else_id))
                query.where(users: { id: team.users.map(&:id) })
              else
                query.where(users: { id: @search.case_owner_is_someone_else_id })
              end
    end

    case @search.teams_with_access
    when "my_team"
      query = query.where(collaboration_accesses_investigations: { collaborator_type: "Team", collaborator_id: user.team.id })
    when "other"
      query = if @search.teams_with_access_other_id.present?
                query.where(collaboration_accesses_investigations: { collaborator_type: "Team", collaborator_id: @search.teams_with_access_other_id })
              else
                query.where.not(collaboration_accesses_investigations: { collaborator_type: "Team", collaborator_id: user.team.id })
              end
    end

    if @search.created_from_date.present?
      query = query.where("investigations.created_at >= ?", @search.created_from_date.at_beginning_of_day)
    end
    if @search.created_to_date.present?
      query = query.where("investigations.created_at <= ?", @search.created_to_date.at_end_of_day)
    end

    query = query.where(state: @search.state) if @search.state.present?

    if ids_only
      query.distinct.pluck(:id)
    else
      pagy(query.order(@search.sorting_params), page_param:)
    end
  end

  def query_params
    params.permit(
      :q,
      :case_status,
      :case_status_open,
      :case_status_closed,
      :case_type,
      *CASE_TYPES,
      :page,
      :case_owner,
      :case_owner_me,
      :case_owner_my_team,
      :case_owner_other,
      :sort_by,
      :sort_dir,
      :priority,
      :serious,
      :high,
      :medium,
      :low,
      :not_set,
      :teams_with_access,
      :case_owner_is_someone_else_id,
      :teams_with_access_other_id,
      :created_by,
      :created_by_other_id,
      :created_by_me,
      :created_by_my_team,
      :created_by_others,
      :page_name,
      :hazard_type,
      *HAZARD_PARAMS,
      *REPORTED_REASONS,
      :teams_with_access_my_team,
      :teams_with_access_others,
      created_from_date: %i[day month year],
      created_to_date: %i[day month year],
    )
  end

  def notification_export_params
    params.permit(
      :q,
      :case_status,
      :case_status_open,
      :case_status_closed,
      :case_type,
      *CASE_TYPES,
      :case_owner,
      :case_owner_me,
      :case_owner_my_team,
      :case_owner_other,
      :priority,
      :serious,
      :high,
      :medium,
      :low,
      :not_set,
      :teams_with_access,
      :case_owner_is_someone_else_id,
      :teams_with_access_other_id,
      :created_by,
      :created_by_other_id,
      :created_by_me,
      :created_by_my_team,
      :created_by_others,
      :hazard_type,
      *HAZARD_PARAMS,
      *REPORTED_REASONS,
      :teams_with_access_my_team,
      :teams_with_access_others,
      created_from_date: %i[day month year],
      created_to_date: %i[day month year]
    )
  end

  def sorting_params
    return {} if params[:sort_by] == SortByHelper::SORT_BY_RELEVANT
    return { trading_name: :desc } if params[:sort_by] == SortByHelper::SORT_BY_NAME && params[:sort_dir] == SortByHelper::SORT_DIRECTION_DESC
    return { trading_name: :asc } if params[:sort_by] == SortByHelper::SORT_BY_NAME

    { updated_at: :desc }
  end

  def sort_column
    Investigation.column_names.include?(params[:sort_by]) ? params[:sort_by] : :updated_at
  end

  def sort_direction
    SortByHelper::SORT_DIRECTIONS.include?(params[:sort_dir]) ? params[:sort_dir] : :desc
  end

  def page_number
    params[:page].to_i > 500 ? "500" : params[:page]
  end

  def searching_for_investigation_pretty_id?(query)
    query.match(/\d{4}-\d{4}/)
  end

  def safety_and_compliance_rows(investigation)
    rows = []

    reported_reason = investigation.reported_reason ? investigation.reported_reason.to_sym : :not_provided

    rows << {
      key: { text: t(:reported_as, scope: "investigations.overview.safety_and_compliance") },
      value: { text: simple_format(t(reported_reason.to_sym, scope: "investigations.overview.safety_and_compliance")) },
    }

    if investigation.unsafe_and_non_compliant? || investigation.unsafe?
      rows << {
        key: { text: t(:primary_hazard, scope: "investigations.overview.safety_and_compliance") },
        value: { text: simple_format(investigation.hazard_type) },
      }

      rows << {
        key: { text: t(:description, scope: "investigations.overview.safety_and_compliance") },
        value: { text: "<span class='govuk-!-font-size-16'>#{investigation.hazard_description}</span>".html_safe }
      }
    end

    if investigation.unsafe_and_non_compliant? || investigation.non_compliant?
      rows << {
        key: { text: t(:key, scope: "investigations.overview.compliance") },
        value: { text: simple_format(investigation.non_compliant_reason) },
      }
    end

    rows
  end

  def investigation_product_rows(investigation_product = nil, user = nil)
    [
      {
        key: { text: "<span id='case_batch_numbers_#{investigation_product&.id}'>Batch numbers</span>".html_safe },
        value: { text: investigation_product&.batch_number || "" },
        actions: batch_number_actions(investigation_product, user)
      },
      {
        key: { text: "<span id='case_customs_codes_#{investigation_product&.id}'>Customs codes</span>".html_safe },
        value: { text: investigation_product&.customs_code || "" },
        actions: customs_code_actions(investigation_product, user)
      },
      {
        key: { text: "<span id='case_ucr_numbers_#{investigation_product&.id}'>UCR numbers</span>".html_safe },
        value: {
          text: ucr_number_unordered_list(investigation_product&.ucr_numbers_list) || ""
        },
        actions: ucr_numbers_actions(investigation_product, user)
      },
      {
        key: { text: "<span id='case_units_affected_#{investigation_product&.id}'>Units affected</span>".html_safe },
        value: units_affected(investigation_product),
        actions: number_of_affected_units_actions(investigation_product, user)
      }
    ]
  end

  def ucr_number_unordered_list(ucr_numbers)
    return if ucr_numbers.blank?

    tag.ul class: "govuk-list govuk-list--bullet" do
      content = ucr_numbers.collect do |ucr|
        content_tag :li, ucr
      end
      content.join.html_safe
    end
  end

  def units_affected(investigation_product)
    return { text: "" } unless investigation_product&.affected_units_status

    if investigation_product.number_of_affected_units.blank?
      { text: I18n.t("product.affected_units_status.#{investigation_product.affected_units_status}") }
    else
      { text: "#{investigation_product.number_of_affected_units} <span class='govuk-!-font-size-16 govuk-!-padding-left-2 opss-secondary-text'>#{I18n.t("product.affected_units_status.#{investigation_product.affected_units_status}")} number</span>".html_safe }
    end
  end

  def details_for_products_tab(investigation)
    title_link = link_to investigation.title, investigation_path(investigation), class: "govuk-link"

    [
      { key: { text: "Notification" }, value: { text: investigation.pretty_id } },
      { key: { text: "Name" }, value: { text: title_link } },
      { key: { text: "Team" }, value: { text: investigation.owner_team.name } },
      { key: { text: "Created" }, value: { text: investigation.created_at.to_formatted_s(:govuk) } },
      { key: { text: "Status" }, value: status_value(investigation) }
    ]
  end

  def case_rows(investigation, user, team_list_html)
    rows = [
      {
        key: { text: "Notification name" },
        value: { text: investigation.title },
        actions: case_name_actions(investigation, user)
      },
      {
        key: { text: "Notification number" },
        value: { text: investigation.pretty_id }
      },
      {
        key: { text: "Reference" },
        value: { text: investigation.complainant_reference },
        actions: reference_actions(investigation, user)
      },
      {
        key: { text: "Summary" },
        value: { text: summary_html(investigation) },
        actions: summary_actions(investigation, user)
      },
      {
        key: { text: "Status" },
        value: status_value(investigation),
        actions: status_actions(investigation, user),
      },
      {
        key: { text: "Last updated" },
        value: { text: time_ago_or_date(@investigation.updated_at) }
      },
      {
        key: { text: "Created" },
        value: { text: time_ago_or_date(@investigation.created_at) }
      },
      {
        key: { text: "Created by" },
        value: { text: investigation.created_by }
      },
      {
        key: { text: "Notification owner" },
        value: { text: investigation_owner(investigation) },
        actions: case_owner_actions(investigation, user)
      },
      {
        key: { text: "Teams added" },
        value: { text: team_list_html },
        actions: case_teams_actions(investigation)
      }
    ]

    if investigation.is_private?
      rows << {
        key: { text: "Notification restriction" },
        value: { text: case_restriction_value(investigation) },
        actions: case_restriction_actions(investigation, user)
      }
    end

    rows << [
      {
        key: { text: "Notification risk level" },
        value: { text: case_risk_level_value(investigation) },
        actions: risk_level_actions(investigation, user)
      },
      {
        key: { text: 'Risk <span class="govuk-visually-hidden">level</span> validated'.html_safe },
        value: { text: risk_validated_value(investigation) },
        actions: risk_validation_actions(investigation, user)
      }
    ]
    rows.flatten!

    if investigation.coronavirus_related
      rows << {
        key: { text: "COVID-19" },
        value: { text: '<span class="opss-tag opss-tag--covid opss-tag--lrg">COVID-19 related</span>'.html_safe }
      }
    end

    if policy(investigation).view_notifying_country?(user:)
      rows << {
        key: { text: "Notifying country" },
        value: { text: country_from_code(investigation.notifying_country, Country.notifying_countries) },
        actions: notifying_country_actions(investigation, user)
      }
    end

    if policy(investigation).view_overseas_regulator?(user:)
      rows << {
        key: { text: "Overseas regulator" },
        value: { text: overseas_regulator_value(investigation) },
        actions: overseas_regulator_actions(investigation, user)
      }
    end

    rows
  end

  def search_result_statement(search_terms, number_of_results)
    search_result_values = search_result_values(search_terms, number_of_results)

    render "investigations/search_result", word: search_result_values[:word], number_of_cases_in_english: search_result_values[:number_of_cases_in_english], search_terms:
  end

  def risk_validated_link_text(investigation)
    investigation.risk_validated_by ? "Change" : t("investigations.risk_validation.validate")
  end

  def form_serialisation_option
    options = {}
    options[:except] = :sort_by if params[:sort_by] == SortByHelper::SORT_BY_RELEVANT

    options
  end

  def options_for_notifying_country(countries, notifying_country_form)
    countries.map do |country|
      text = country[0]
      value = country[1]
      option = { text:, value: }
      option[:selected] = true if notifying_country_form.country == value
      option
    end
  end

  def options_for_overseas_regulator(countries, overseas_regulator_form)
    countries = countries.map do |country|
      text = country[0]
      option = OpenStruct.new(text:, value: country[1])
      option[:selected] = true if overseas_regulator_form.notifying_country == text
      option
    end
    countries.unshift(OpenStruct.new(text: "", value: ""))
    countries
  end

  def non_search_cases_page_names
    %w[team_cases your_cases assigned_cases].freeze
  end

  def calculate_row_index(investigation_counter, row_number)
    # Each investigation has 3 rows (title, meta, status)
    # So for investigation 0, rows are 1,2,3
    # For investigation 1, rows are 4,5,6 etc.
    (investigation_counter * 3) + row_number
  end

  def investigation_owner(investigation)
    sanitize(investigation.owner_display_name_for(viewer: current_user))
  end

  # Include the new table accessibility helper
  include TableAccessibilityHelper

private

  def search_result_values(_search_terms, number_of_results)
    word = number_of_results == 1 ? "was" : "were"

    number_of_cases_in_english = "#{number_of_results} #{'notification'.pluralize(number_of_results)}"

    {
      number_of_cases_in_english:,
      word:
    }
  end

  def case_name_actions(investigation, user)
    return [] unless policy(investigation).update?(user:)

    [
      {
        href: edit_investigation_case_names_path(investigation.pretty_id),
        text: "Edit",
        visually_hidden_text: "the notification name"
      }
    ]
  end

  def reference_actions(investigation, user)
    return [] unless policy(investigation).update?(user:)

    [
      {
        href: edit_investigation_reference_numbers_path(investigation.pretty_id),
        text: "Edit",
        visually_hidden_text: "the reference number"
      }
    ]
  end

  def summary_actions(investigation, user)
    return [] unless policy(investigation).update?(user:)

    [
      {
        href: edit_investigation_summary_path(investigation.pretty_id),
        text: "Edit",
        visually_hidden_text: "the summary"
      }
    ]
  end

  def status_actions(investigation, user)
    return [] unless policy(investigation).change_owner_or_status?(user:)

    status_path = investigation.is_closed ? reopen_investigation_status_path(investigation) : close_investigation_status_path(investigation)
    status_link_text = investigation.is_closed? ? "Re-open" : "Close"

    [
      {
        href: status_path,
        text: status_link_text,
        visually_hidden_text: "this notification"
      }
    ]
  end

  def notifying_country_actions(investigation, user)
    return [] unless policy(investigation).change_notifying_country?(user:)

    [
      {
        href: edit_investigation_notifying_country_path(investigation),
        text: "Change",
        visually_hidden_text: "notifying country"
      }
    ]
  end

  def overseas_regulator_actions(investigation, user)
    return [] unless policy(investigation).change_overseas_regulator?(user:)

    [
      {
        href: edit_investigation_overseas_regulator_path(investigation),
        text: "Change",
        visually_hidden_text: "overseas regulator"
      }
    ]
  end

  def case_owner_actions(investigation, user)
    return [] unless policy(investigation).change_owner_or_status?(user:)

    [
      {
        href: new_investigation_ownership_path(investigation),
        text: "Edit",
        visually_hidden_text: "the notification owner"
      }
    ]
  end

  def case_teams_actions(investigation)
    return [] unless policy(investigation).manage_collaborators?

    [
      {
        href: investigation_collaborators_path(investigation),
        text: "Change",
        visually_hidden_text: "the teams added"
      }
    ]
  end

  def case_restriction_actions(investigation, user)
    return [] unless policy(investigation).can_unrestrict?(user:)

    [
      {
        href: investigation_visibility_path(investigation),
        text: "Change",
        visually_hidden_text: "the notification restriction"
      }
    ]
  end

  def risk_level_actions(investigation, user)
    return [] unless policy(investigation).update?(user:)

    [
      {
        href: investigation_risk_level_path(investigation),
        text: "Change",
        visually_hidden_text: "the risk level"
      }
    ]
  end

  def batch_number_actions(investigation_product, user)
    return [] unless investigation_product && policy(investigation_product.investigation).update?(user:)

    [
      href: edit_investigation_product_batch_numbers_path(investigation_product),
      text: "Edit",
      visually_hidden_text: "the batch numbers for #{investigation_product.name}"
    ]
  end

  def customs_code_actions(investigation_product, user)
    return [] unless investigation_product && policy(investigation_product.investigation).update?(user:)

    [
      href: edit_investigation_product_customs_code_path(investigation_product),
      text: "Edit",
      visually_hidden_text: "the customs codes for #{investigation_product.name}"
    ]
  end

  def ucr_numbers_actions(investigation_product, user)
    return [] unless investigation_product && policy(investigation_product.investigation).update?(user:)

    [
      href: edit_investigation_product_ucr_numbers_path(investigation_product),
      text: "Edit",
      visually_hidden_text: "the UCR numbers for #{investigation_product.name}"
    ]
  end

  def number_of_affected_units_actions(investigation_product, user)
    return [] unless investigation_product && policy(investigation_product.investigation).update?(user:)

    [
      href: edit_investigation_product_number_of_affected_units_path(investigation_product),
      text: "Edit",
      visually_hidden_text: "the units affected for #{investigation_product.name}"
    ]
  end

  def risk_validation_actions(investigation, user)
    return [] unless policy(Investigation).risk_level_validation? && investigation.teams_with_access.include?(user.team)

    [
      {
        href: edit_investigation_risk_validations_path(investigation.pretty_id),
        text: risk_validated_link_text(investigation)
      }
    ]
  end

  def status_value(investigation)
    if investigation.is_closed?
      {
        text: "<span class=\"opss-tag opss-tag--risk3\">Notification closed</span> (#{investigation.date_closed.to_formatted_s(:govuk)})".html_safe
      }
    else
      {
        text: "Open"
      }
    end
  end

  def case_restriction_value(investigation)
    investigation.is_private ? '<span class="opss-tag opss-tag--risk2 opss-tag--lrg"><span class="govuk-visually-hidden">This notification is </span>Restricted'.html_safe : "Unrestricted"
  end

  def case_risk_level_value(investigation)
    %w[high serious].include?(investigation.risk_level) ? "<span class='opss-tag opss-tag--risk1 opss-tag--lrg'>#{investigation.risk_level.capitalize} risk</span>".html_safe : investigation.risk_level_description
  end

  def risk_validated_value(investigation)
    if investigation.risk_validated_by
      t("investigations.risk_validation.validated_status", risk_validated_by: investigation.risk_validated_by, risk_validated_at: investigation.risk_validated_at.strftime("%d %B %Y"))
    else
      t("investigations.risk_validation.not_validated")
    end
  end

  def overseas_regulator_value(investigation)
    return if investigation.is_from_overseas_regulator.nil?

    investigation.is_from_overseas_regulator ? country_from_code(investigation.notifying_country, Country.overseas_countries) : t("investigations.overseas_regulator.no")
  end

  def summary_html(investigation)
    "<span class='opss-text-limit-scroll-s'>#{investigation.object.description}</span>".html_safe
  end

  def time_ago_or_date(date)
    if date > 24.hours.ago
      "#{time_ago_in_words(date).capitalize} ago"
    else
      date.to_formatted_s(:govuk)
    end
  end

  def scroll_time(scroll)
    return nil unless scroll

    "1m"
  end
end
