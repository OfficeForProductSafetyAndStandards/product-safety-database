class InvestigationDecorator < ApplicationDecorator
  delegate_all
  decorates_associations :complainant, :documents_attachments, :creator_user, :owner_user, :owner_team

  PRODUCT_DISPLAY_LIMIT = 6

  def title
    user_title
  end

  def hazard_description
    h.simple_format(object.hazard_description)
  end

  def non_compliant_reason
    h.simple_format(object.non_compliant_reason)
  end

  def description
    h.simple_format(object.description)
  end

  def display_product_summary_list?
    products.any?
  end

  def product_summary_list
    products_details = [products.count, "product".pluralize(products.count), "added"].join(" ")
    rows = [
      category.present? ? { key: { text: "Category" }, value: { text: category }, actions: [] } : nil,
      {
        key: { text: "Product details" },
        value: { text: products_details },
        actions: [href: h.investigation_products_path(object), visually_hidden_text: "product details", text: "View"]
      },
    ]
    rows.compact!
    h.render "components/govuk_summary_list", rows: rows, classes: "govuk-summary-list--no-border"
  end

  def display_risk_and_issues_list?
    object.hazard_type.present? || object.non_compliant_reason.present?
  end

  def risk_and_issues_list
    hazards = h.simple_format([hazard_type, object.hazard_description].join("\n\n"))
    rows = [
      object.hazard_type.present? ? { key: { text: "Hazards" }, value: { text: hazards }, actions: [] } : nil,
      object.non_compliant_reason.present? ? { key: { text: "Compliance" }, value: { text: non_compliant_reason }, actions: [] } : nil,
    ]
    rows.compact!
    h.render "components/govuk_summary_list", rows: rows, classes: "govuk-summary-list--no-border"
  end

  def source_details_summary_list(view_protected_details = false)
    contact_details = h.tag.p(I18n.t("case.protected_details", data_type: "#{object.case_type} contact details"), class: "govuk-hint")
    contact_details << complainant.contact_details if view_protected_details

    rows = [
      should_display_date_received? ? { key: { text: "Received date" }, value: { text: date_received.to_s(:govuk) } } : nil,
      should_display_received_by? ? { key: { text: "Received by" }, value: { text: received_type.upcase_first } } : nil,
      { key: { text: "Source type" }, value: { text: complainant.complainant_type } },
      { key: { text: "Contact details" }, value: { text: contact_details } }
    ]

    rows.compact!

    h.render "components/govuk_summary_list", rows: rows, classes: "govuk-summary-list--no-border"
  end

  def pretty_description
    "#{case_type.upcase_first}: #{pretty_id}"
  end

  def created_by
    return if creator_user.nil?

    out = []
    out << h.escape_once(creator_user.full_name)
    out << h.escape_once(creator_user.team.name)

    out.join("<br />").html_safe
  end

  def products_list
    product_count = products.count
    limit         = PRODUCT_DISPLAY_LIMIT

    limit += 1 if product_count - PRODUCT_DISPLAY_LIMIT == 1

    products_remaining_count = products.offset(limit).count

    h.tag.ul(class: "govuk-list") do
      h.concat(h.render(products.limit(limit)))
      if product_count > limit
        h.concat(h.link_to("View #{products_remaining_count} more products...", h.investigation_products_path(object)))
      end
    end
  end

  def owner_display_name_for(viewer:)
    return "No case owner" unless investigation.owner

    owner.owner_short_name(viewer: viewer)
  end

  def generic_attachment_partial(viewing_user)
    return "documents/restricted_generic_document_card" unless Pundit.policy!(viewing_user, object).view_protected_details?(user: viewing_user)

    "documents/generic_document_card"
  end

  def owner
    object.owner&.decorate
  end

private

  def category
    @category ||= \
      begin
        categories = [object.product_category]
        categories += products.map(&:category)
        categories.uniq!
        categories.compact!
        if categories.size == 1
          h.simple_format(categories.first.downcase.upcase_first, class: "govuk-body")
        else
          h.tag.ul(class: "govuk-list") do
            lis = categories.map { |cat| h.tag.li(cat.downcase.upcase_first) }
            lis.join.html_safe
          end
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
