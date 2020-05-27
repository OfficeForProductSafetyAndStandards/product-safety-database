class InvestigationDecorator < ApplicationDecorator
  delegate_all
  decorates_associations :complainant, :documents_attachments, :owner, :source

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
    hazards = h.simple_format([hazard_type, object.hazard_description].join("\n\n"))
    rows = [
      category.present? ? { key: { text: "Category" }, value: { text: category }, actions: [] } : nil,
      {
        key: { text: "Product details" },
        value: { text: products_details },
        actions: [href: h.investigation_products_path(object), visually_hidden_text: "product details", text: "View"]
      },
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

  # rubocop:disable Rails/OutputSafety
  def created_by
    return if source.nil?

    out = []
    out << if source.user.nil?
             h.tag.div("Unknown")
           else
             h.escape_once(source.user.full_name.to_s)
           end
    out << h.escape_once(source.user.team.name) if source&.user&.team

    out.join("<br />").html_safe
  end
  # rubocop:enable Rails/OutputSafety

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

private

  # rubocop:disable Rails/OutputSafety
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
  # rubocop:enable Rails/OutputSafety

  def should_display_date_received?
    false
  end

  def should_display_received_by?
    false
  end
end
