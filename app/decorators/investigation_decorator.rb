class InvestigationDecorator < ApplicationDecorator
  include FormattedDescription
  include ActionView::Helpers::OutputSafetyHelper
  delegate_all
  decorates_associations :complainant, :documents_attachments, :creator_user, :owner_user, :owner_team, :activities, :risk_assessments

  PRODUCT_DISPLAY_LIMIT = 6

  def title
    user_title || complainant_reference || pretty_id
  end

  def unformatted_description
    # Bypasses `FormattedDescription` for situations where we want the raw value of the field.
    object.description
  end

  def risk_assessment_risk_levels
    risk_assessments.collect(&:risk_level_description).uniq
  end

  def risk_level_set?
    object.risk_level.present? || object.custom_risk_level.present?
  end

  def risk_level_description
    if object.risk_level.present? && !object.other?
      I18n.t(".investigations.risk_level.show.levels.#{object.risk_level}")
    elsif object.custom_risk_level.present?
      object.custom_risk_level
    else
      "Not set"
    end
  end

  def case_title_key(viewing_user)
    if object.is_private? && !viewing_user.has_role?(:super_user)
      "Notification restricted"
    else
      h.link_to(title, h.investigation_path(object), class: "govuk-link govuk-link--no-visited-state")
    end
  end

  def case_summary_values
    values = []

    if investigation.is_private?
      values << { text: "" }
      values << { text: "" }
    else
      values << { text: object.pretty_id }
      values << { text: object.owner_team&.name || "&ndash;".html_safe }
    end

    values << { text: status }

    values
  end

  def source_details_summary_list(view_protected_details: false)
    contact_details = view_protected_details ? contact_details_list : h.tag.p("")
    contact_details << h.tag.p(I18n.t("case.protected_details", data_type: "#{object.case_type} contact details"), class: "govuk-body-s govuk-!-margin-bottom-1 opss-secondary-text opss-text-align-right")

    rows = [
      should_display_date_received? ? { key: { text: "Received date" }, value: { text: date_received.to_formatted_s(:govuk) } } : nil,
      should_display_received_by? ? { key: { text: "Received by" }, value: { text: received_type.upcase_first } } : nil,
      { key: { text: "Source type" }, value: { text: complainant.complainant_type } },
      { key: { text: "Contact details" }, value: { text: contact_details } }
    ]

    rows.compact!

    h.govuk_summary_list(rows:, borders: false, classes: "opss-summary-list-mixed opss-summary-list-mixed--narrow-dt")
  end

  def contact_details_list
    h.tag.ul(class: "govuk-list govuk-list--bullet govuk-list--spaced") do
      lis = []
      lis << h.tag.li(complainant.name) if complainant.name.present?
      lis << h.tag.li("Telephone: #{complainant.phone_number}") if complainant.phone_number.present?
      lis << h.tag.li("Email: ".html_safe + h.mail_to(complainant.email_address, class: "govuk-link govuk-link--no-visited-state")) if complainant.email_address.present?
      lis << h.tag.li(complainant.other_details) if complainant.other_details.present?
      safe_join(lis)
    end
  end

  def pretty_description
    "Notification: #{pretty_id}"
  end

  def created_by
    return if creator_user.nil?

    "#{creator_user.full_name} - #{creator_user.team.name}"
  end

  def owner_display_name_for(viewer:)
    return "No notification owner" unless investigation.owner

    owner.owner_short_name(viewer:)
  end

  def generic_attachment_partial(viewing_user)
    return "documents/restricted_generic_document_card" unless Pundit.policy!(viewing_user, object).view_protected_details?(user: viewing_user)

    "documents/generic_document_card"
  end

  def owner
    object.owner&.decorate
  end

  def status
    is_closed? ? "Closed" : "Open"
  end

  def visibility_status
    is_private? ? "restricted" : "unrestricted"
  end

  def visibility_action
    is_private? ? "unrestrict" : "restrict"
  end

private

  def category
    @category ||= \
      if categories.size == 1
        h.simple_format(categories.first.downcase.upcase_first, class: "govuk-body")
      else
        h.tag.ul(class: "govuk-list") do
          lis = categories.map { |cat| h.tag.li(cat.downcase.upcase_first) }
          lis.join.html_safe
        end
      end
  end

  def should_display_date_received?
    false
  end

  def should_display_received_by?
    false
  end
end
