class InvestigationDecorator < ApplicationDecorator
  delegate_all

  def title
    user_title
  end

  def display_product_summary_list?
    products.any?
  end

  def product_summary_list
    products_details = [products.count, "product".pluralize(products.count), "added"].join(" ")
    hazards = h.simple_format([hazard_type, hazard_description].join("\n\n"))
    rows = [
      category.present? ? { key: { text: "Category" }, value: { text: category }, actions: [] } : nil,
      {
        key: { text: "Product details" },
        value: { text: products_details },
        actions: [href: h.investigation_products_path(object), visually_hidden_text: "product details", text: "View"]
      },
      hazard_type.present? ? { key: { text: "Hazards" }, value: { text: hazards }, actions: [] } : nil,
      non_compliant_reason.present? ? { key: { text: "Compliance" }, value: { text: h.simple_format(non_compliant_reason) }, actions: [] } : nil,
    ]
    rows.compact!
    h.render "components/govuk_summary_list", rows: rows, classes: "govuk-summary-list--no-border"
  end

  def investigation_summary_list(include_actions: true, classes: "")
    rows = [
      {
        key: { text: "Status", classes: classes },
        value: { text: status, classes: classes },
        actions: []
      },
      {
        key: { text: "Created by", classes: classes },
        value: { text: creator, classes: classes },
        actions: []
      },
      {
        key: { text: "Assigned to", classes: classes },
        value: { text: h.investigation_assignee(object, classes) },
      },
      # TODO: Created by should contain the creator's organisation a bit like in
      # def investigation_assignee(investigation, classes = "")
      {
        key: { text: "Date created", classes: classes },
        value: { text: investigation.created_at.beginning_of_month.to_s(:govuk), classes: classes },
        actions: []
      },
      {
        key: { text: "Last updated", classes: classes },
        value: { text: "#{h.time_ago_in_words(investigation.updated_at)} ago", classes: classes }
      },
      complainant_reference.present? ? { key: { text: "Trading Standards reference", classes: classes }, value: { text: complainant_reference, classes: classes }, actions: [] } : nil
    ]
    rows.compact!

    if include_actions
      rows[0][:actions] = [
        { href: h.status_investigation_path(investigation), text: "Change", classes: classes, visually_hidden_text: "status" }
      ]
      rows[2][:actions] = [
        { href: h.new_investigation_assign_path(investigation), text: "Change", classes: classes, visually_hidden_text: "assigned to" }
      ]
      rows[4][:actions] = [
        { href: h.new_investigation_activity_path(investigation), text: "Add activity", classes: classes }
      ]
    end

    h.render "components/govuk_summary_list", rows: rows, classes: "govuk-summary-list--no-border"
  end

  def source_details_summary_list
    contact_details = if complainant.can_be_displayed?
                        complainant.decorate.contact_details
                      else
                        "Reporter details are restricted because they contain GDPR protected data."
                      end
    rows = [
      date_received? ? { key: { text: "Received date" }, value: { text: date_received.to_s(:govuk) } } : nil,
      received_type? ? { key: { text: "Received by" }, value: { text: received_type.upcase_first } } : nil,
      { key: { text: "Source type" }, value: { text: complainant.complainant_type } },
      { key: { text: "Contact details" }, value: { text: contact_details } }
    ]

    rows.compact!

    h.render "components/govuk_summary_list", rows: rows, classes: "govuk-summary-list--no-border"
  end

  def pretty_description
    "#{case_type.titleize}: #{pretty_id}"
  end

private

  def creator
    source.user.name.upcase_first if source&.user.present?
  end

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
            lis = categories.map { |cat| h.tag.li(h.escape_once(cat.downcase.upcase_first)) }
            lis.join.html_safe
          end
        end
      end
  end
  # rubocop:enable Rails/OutputSafety
end
