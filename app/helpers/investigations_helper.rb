module InvestigationsHelper
  include InvestigationSearchHelper

  def search_for_investigations(page_size = Investigation.count, user = current_user)
    result = Investigation.full_search(search_query(user))
    result.page(page_number).per(page_size)
  end

  def query_params
    params.permit(
      :q,
      :case_status,
      :case_type,
      :page,
      :case_owner,
      :sort_by,
      :sort_dir,
      :priority,
      :teams_with_access,
      :case_owner_is_someone_else_id,
      :teams_with_access_other_id,
      :created_by,
      :created_by_other_id,
      :page_name
    )
  end

  def export_params
    query_params.except(:page, :sort_by, :page_name)
  end

  def build_breadcrumb_structure
    {
      items: [
        {
          text: "Cases",
          href: investigations_path
        },
        {
          text: @investigation.pretty_description
        }
      ]
    }
  end

  def risks_and_issues_rows(investigation, user)
    risk_level_row = {
      key: {
        text: t(:key, scope: "investigations.overview.case_risk_level")
      },
      value: { text: investigation.risk_level_description }
    }

    if policy(investigation).update?(user:)
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

    if policy(investigation).update?(user:) || most_recent_risk_assessment

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

    [risk_level_row, validated_row, risk_assessment_row]
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
        value: { text: simple_format(investigation.hazard_description) },
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

  def search_result_statement(search_terms, number_of_results)
    search_result_values = search_result_values(search_terms, number_of_results)

    render "investigations/search_result", word: search_result_values[:word], number_of_cases_in_english: search_result_values[:number_of_cases_in_english], search_terms:
  end

  def risk_validated_link_text(investigation)
    investigation.risk_validated_by ? "Change" : t("investigations.risk_validation.validate")
  end

  # This builds an array from an investigation which can then
  # be passed as a `rows` argument to the govukSummaryList() helper.
  def about_the_case_rows(investigation, user)
    status_actions = { items: [] }
    activity_actions = { items: [] }
    notifying_country_actions = { items: [] }

    if policy(investigation).update?(user:)
      activity_actions[:items] << {
        href: new_investigation_supporting_information_path(investigation),
        text: "Add supporting information"
      }
    end

    if policy(investigation).change_owner_or_status?(user:)
      status_actions[:items] << if investigation.is_closed?
                                  {
                                    href: reopen_investigation_status_path(investigation),
                                    text: "Re-open",
                                    visuallyHiddenText: "case"
                                  }
                                else
                                  {
                                    href: close_investigation_status_path(investigation),
                                    text: "Close",
                                    visuallyHiddenText: "case"
                                  }
                                end
    end

    if policy(investigation).change_notifying_country?(user:)
      notifying_country_actions[:items] << {
        href: edit_investigation_notifying_country_path(investigation),
        text: "Change",
        visuallyHiddenText: "notifying_country"
      }
    end

    rows = [
      {
        key: { text: "Status" },
        value: { text: investigation.status },
        actions: status_actions
      },
      {
        key: { text: "Created by" },
        value: { text: investigation.created_by }
      },
      {
        key: { text: "Notifying country" },
        value: { text: country_from_code(investigation.notifying_country, Country.notifying_countries) },
        actions: notifying_country_actions
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

    if investigation.coronavirus_related
      coronavirus_row = { key: { text: "Coronavirus related" }, value: { text: I18n.t(investigation.coronavirus_related, scope: "case.coronavirus_related") } }
      rows.insert(1, coronavirus_row)
    end

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
        path: new_investigation_document_path(investigation),
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
        path: new_investigation_document_path(investigation),
        text: "Other document or attachment"
      },
      {
        path: new_investigation_product_path(investigation),
        text: "Product"
      },
      {
        path: new_investigation_business_path(investigation),
        text: "Business"
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

      visibility_status = investigation.is_private? ? "restricted" : "unrestricted"
      risk_level_status = investigation.risk_level ? "set" : "not_set"

      actions << if investigation.is_closed?
                   {
                     path: reopen_investigation_status_path(@investigation),
                     text: I18n.t("reopen_case", scope: "forms.investigation_actions.actions")
                   }
                 else
                   {
                     path: close_investigation_status_path(@investigation),
                     text: I18n.t("close_case", scope: "forms.investigation_actions.actions")
                   }
                 end

      actions << {
        path: new_investigation_ownership_path(@investigation),
        text: I18n.t(:change_case_owner, scope: "forms.investigation_actions.actions")
      }

      actions << {
        path: investigation_visibility_path(@investigation),
        text: I18n.t("change_case_visibility.#{visibility_status}", scope: "forms.investigation_actions.actions")
      }

      actions << {
        path: investigation_risk_level_path(@investigation),
        text: I18n.t("change_case_risk_level.#{risk_level_status}", scope: "forms.investigation_actions.actions")
      }
    end

    if policy(investigation).send_email_alert?
      actions << {
        path: about_investigation_alerts_path(@investigation),
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

  def form_serialisation_option
    options = {}
    options[:except] = :sort_by if params[:sort_by] == SortByHelper::SORT_BY_RELEVANT

    options
  end

  def options_for_notifying_country(countries, notifying_country_form)
    countries.map do |country|
      text = country[0]
      option = { text:, value: country[1] }
      option[:selected] = true if notifying_country_form.country == text
      option
    end
  end

private

  def search_result_values(_search_terms, number_of_results)
    word = number_of_results == 1 ? "was" : "were"

    number_of_cases_in_english = "#{number_of_results} #{'case'.pluralize(number_of_results)}"

    {
      number_of_cases_in_english:,
      word:
    }
  end
end
