module InvestigationsHelper
  include InvestigationSearchHelper

  def search_for_investigations(page_size = Investigation.count, user = current_user)
    result = Investigation.not_deleted.full_search(search_query(user))
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
      :page_name,
      :hazard_type
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
        key: { text: "Batch numbers" },
        value: { text: investigation_product&.batch_number || "" },
        actions: batch_number_actions(investigation_product, user)
      },
      {
        key: { text: "Customs codes" },
        value: { text: investigation_product&.customs_code || "" },
        actions: customs_code_actions(investigation_product, user)
      },
      {
        key: { text: "Units affected" },
        value: units_affected(investigation_product),
        actions: number_of_affected_units_actions(investigation_product, user)
      }
    ]
  end

  def units_affected(investigation_product)
    return { text: "" } unless investigation_product&.affected_units_status

    if investigation_product.number_of_affected_units.blank?
      { text: I18n.t("product.affected_units_status.#{investigation_product.affected_units_status}") }
    else
      { html: "#{investigation_product.number_of_affected_units} <span class='govuk-!-font-size-16 govuk-!-padding-left-2 opss-secondary-text'>#{I18n.t("product.affected_units_status.#{investigation_product.affected_units_status}")} number</span>".html_safe }
    end
  end

  def details_for_products_tab(investigation)
    title_link = link_to investigation.title, investigation_path(investigation), class: "govuk-link govuk-link--no-visited-state"

    [
      { key: { text: "Case" }, value: { text: investigation.pretty_id } },
      { key: { text: "Name" }, value: { html: title_link } },
      { key: { text: "Team" }, value: { text: investigation.owner_team.name } },
      { key: { text: "Created" }, value: { text: investigation.created_at.to_formatted_s(:govuk) } },
      { key: { text: "Status" }, value: status_value(investigation) }
    ]
  end

  def case_rows(investigation, user, team_list_html)
    reference_value = { text: investigation.complainant_reference }
    reference_value[:secondary_text] = { text: "Optional reference number" } if investigation.complainant_reference

    rows = [
      {
        key: { text: "Case name" },
        value: { text: investigation.title },
        actions: case_name_actions(investigation, user)
      },
      {
        key: { text: "Case number" },
        value: {
          text: investigation.pretty_id,
        },
        actions: {}
      },
      {
        key: { text: "Reference" },
        value: reference_value,
        actions: reference_actions(investigation, user)
      },
      {
        key: { text: "Summary" },
        value: {
          html: summary_html(investigation)
        },
        actions: summary_actions(investigation, user)
      },
      {
        key: { text: "Status" },
        value: status_value(investigation),
        actions: status_actions(investigation, user),
        classes: "opss-summary-list__row--split"
      },
      {
        key: { text: "Last updated" },
        value: {
          text: "#{time_ago_in_words(@investigation.updated_at).capitalize} ago"
        }
      },
      {
        key: { text: "Created" },
        value: {
          text: "#{time_ago_in_words(@investigation.created_at).capitalize} ago"
        }
      },
      {
        key: { text: "Created by" },
        value: {
          text: investigation.created_by
        }
      },
      {
        key: { text: "Case owner" },
        value: {
          text: investigation_owner(investigation)
        },
        actions: case_owner_actions(investigation, user)
      },
      {
        key: { text: "Teams added" },
        value: {
          html: team_list_html
        },
        actions: case_teams_actions(investigation)
      }
    ]

    if investigation.is_private?
      rows << {
        key: { text: "Case restriction" },
        value: {
          html: case_restriction_value(investigation)
        },
        actions: case_restriction_actions(investigation, user)
      }
    end

    rows << [
      {
        key: { text: "Case risk level" },
        value: {
          html: case_risk_level_value(investigation)
        },
        actions: risk_level_actions(investigation, user)
      },
      {
        key: { html: 'Risk <span class="govuk-visually-hidden">level</span> validated'.html_safe },
        value: { text: risk_validated_value(investigation) },
        actions: risk_validation_actions(investigation, user)
      }
    ]
    rows.flatten!

    if investigation.coronavirus_related
      rows << {
        key: { text: "COVID-19" },
        value: {
          html: '<span class="opss-tag opss-tag--covid opss-tag--lrg">COVID-19 related</span>'.html_safe
        },
        actions: {
          items: []
        }
      }
    end

    rows << notifying_country_section(investigation, user) if policy(investigation).view_notifying_country?(user:)

    rows
  end

  def notifying_country_section(investigation, user)
    {
      key: { text: "Notifying country" },
      value: {
        text: country_from_code(investigation.notifying_country, Country.notifying_countries)
      },
      actions: notifying_country_actions(investigation, user)
    }
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

  def non_search_cases_page_names
    %w[team_cases your_cases assigned_cases].freeze
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

  def case_name_actions(investigation, user)
    return {} unless policy(investigation).update?(user:)

    {
      items: [
        href: edit_investigation_case_names_path(investigation.pretty_id),
        text: "Edit",
        visuallyHiddenText: " the case name"
      ]
    }
  end

  def reference_actions(investigation, user)
    return {} unless policy(investigation).update?(user:)

    {
      items: [
        href: edit_investigation_reference_numbers_path(investigation.pretty_id),
        text: "Edit",
        visuallyHiddenText: " the reference number"
      ]
    }
  end

  def summary_actions(investigation, user)
    return {} unless policy(investigation).update?(user:)

    {
      items: [
        href: edit_investigation_summary_path(investigation.pretty_id),
        text: "Edit",
        visuallyHiddenText: " the summary"
      ]
    }
  end

  def status_actions(investigation, user)
    return {} unless policy(investigation).change_owner_or_status?(user:)

    status_path = investigation.is_closed ? reopen_investigation_status_path(investigation) : close_investigation_status_path(investigation)
    status_link_text = investigation.is_closed? ? "Re-open" : "Close"

    {
      items: [
        href: status_path,
        text: status_link_text,
        visuallyHiddenText: " this case"
      ]
    }
  end

  def notifying_country_actions(investigation, user)
    return {} unless policy(investigation).change_notifying_country?(user:)

    {
      items: [
        href: edit_investigation_notifying_country_path(investigation),
        text: "Change",
        visuallyHiddenText: "notifying_country"
      ]
    }
  end

  def case_owner_actions(investigation, user)
    return {} unless policy(investigation).change_owner_or_status?(user:)

    {
      items: [
        href: new_investigation_ownership_path(investigation),
        text: "Change",
        visuallyHiddenText: " the case owner"
      ]
    }
  end

  def case_teams_actions(investigation)
    return {} unless policy(investigation).manage_collaborators?

    {
      items: [
        href: investigation_collaborators_path(investigation),
        text: "Change",
        visuallyHiddenText: " the teams added"
      ]
    }
  end

  def case_restriction_actions(investigation, user)
    return {} unless policy(investigation).can_unrestrict?(user:)

    {
      items: [
        href: investigation_visibility_path(investigation),
        text: "Change",
        visuallyHiddenText: " the case restriction"
      ]
    }
  end

  def risk_level_actions(investigation, user)
    return {} unless policy(investigation).update?(user:)

    {
      items: [
        href: investigation_risk_level_path(investigation),
        text: "Change",
        visuallyHiddenText: " the risk level"
      ]
    }
  end

  def batch_number_actions(investigation_product, user)
    return {} unless investigation_product && policy(investigation_product.investigation).update?(user:)

    {
      items: [
        href: edit_investigation_product_batch_numbers_path(investigation_product),
        text: "Edit",
        visuallyHiddenText: "  the batch numbers for #{investigation_product.name}"
      ]
    }
  end

  def customs_code_actions(investigation_product, user)
    return {} unless investigation_product && policy(investigation_product.investigation).update?(user:)

    {
      items: [
        href: edit_investigation_product_customs_code_path(investigation_product),
        text: "Edit",
        visuallyHiddenText: "  the customs codes for #{investigation_product.name}"
      ]
    }
  end

  def number_of_affected_units_actions(investigation_product, user)
    return {} unless investigation_product && policy(investigation_product.investigation).update?(user:)

    {
      items: [
        href: edit_investigation_product_number_of_affected_units_path(investigation_product),
        text: "Edit",
        visuallyHiddenText: " the units affected for #{investigation_product.name}"
      ]
    }
  end

  def risk_validation_actions(investigation, user)
    return {} unless policy(Investigation).risk_level_validation? && investigation.teams_with_access.include?(user.team)

    {
      items: [
        href: edit_investigation_risk_validations_path(investigation.pretty_id),
        text: risk_validated_link_text(investigation)
      ]
    }
  end

  def status_value(investigation)
    if investigation.is_closed?
      {
        html: '<span class="opss-tag opss-tag--risk3">Case closed</span>'.html_safe,
        secondary_text: { text: investigation.date_closed.to_formatted_s(:govuk) }
      }
    else
      {
        text: "Open"
      }
    end
  end

  def case_restriction_value(investigation)
    investigation.is_private ? '<span class="opss-tag opss-tag--risk2 opss-tag--lrg"><span class="govuk-visually-hidden">This case is </span>Restricted'.html_safe : "Unrestricted"
  end

  def case_risk_level_value(investigation)
    investigation.risk_level == "high" || investigation.risk_level == "serious" ? "<span class='opss-tag opss-tag--risk1 opss-tag--lrg'>#{investigation.risk_level.capitalize} risk</span>".html_safe : investigation.risk_level_description
  end

  def risk_validated_value(investigation)
    if investigation.risk_validated_by
      t("investigations.risk_validation.validated_status", risk_validated_by: investigation.risk_validated_by, risk_validated_at: investigation.risk_validated_at.strftime("%d %B %Y"))
    else
      t("investigations.risk_validation.not_validated")
    end
  end

  def summary_html(investigation)
    "<span class='opss-text-limit-scroll-s'>#{investigation.object.description}</span>".html_safe
  end
end
