class InvestigationDecorator < ApplicationDecorator
  delegate_all

  def title
    user_title
  end

  def product_summary_list
    #TODO: this whole section is conditional see overview text file
    products_details = [products.count, "product".pluralize(products.count), "added"].join(" ")
    hazards = h.simple_format([hazard_type, hazard_description].join("\n\n"))
    rows = [

      {
        key: { text: "Category" },
        value: { text: category },
        actions: []
      },
      {
        key: { text: "Product details" },
        value: { text: products_details },
        actions: [
          { href: h.investigation_products_path(object), visually_hidden_text: "product details", text: "View" }
        ]
      },
      hazard_type.present? ? { key: { text: "Hazards" }, value: { text: hazards }, actions: [] } : nil,
      non_compliant_reason.present? ? { key: { text: "Compliance" }, value: { text: h.simple_format(non_compliant_reason) }, actions: []  } : nil,
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
        value: { text: investigation.source.name, classes: classes },
        actions: []
      },
      {
        key: { text: "Assigned to", classes: classes },
        value: { text: h.investigation_assignee(object, classes) },
      },
      # TODO: Created by should contain the creator's organisation a bit like in
      # def investigation_assignee(investigation, classes = "")
      # TODO: Make this a Date time format to_s(:govuk) =>  strftime("%e %B %Y")
      {
        key: { text: "Date created", classes: classes },
        value: { text: investigation.created_at.beginning_of_month.strftime("%e %B %Y"), classes: classes },
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
    contact_details = [complainant.name, complainant.phone_number, complainant.email_address, complainant.other_details]
    contact_details = ["Not provided"] if contact_details.empty?
    unless complainant.can_be_displayed?
      contact_details = "Reporter details are restricted because they contain GDPR protected data."
    end

    rows = [
      date_received? ? { key: { text: "Received date" }, value: { text: date_received.strftime("%e %B %Y") } } : nil,
      received_type? ? { key: { text: "Received by" }, value: { text: received_type.upcase_first } } : nil,
      { key: { text: "Source type" }, value: { text: complainant.complainant_type } },
      { key: { text: "Contact details" }, value: { text: h.simple_format(contact_details.join("\n\n")) } }
    ]

    if complainant.can_be_displayed?
    end
    rows.compact!

    h.render "components/govuk_summary_list", rows: rows, classes: "govuk-summary-list--no-border"
  end

  def source_details_summary_list
    contact_details = [complainant.name, complainant.phone_number, complainant.email_address, complainant.other_details]
    contact_details = ["Not provided"] if contact_details.empty?
    unless complainant.can_be_displayed?
      contact_details = "Reporter details are restricted because they contain GDPR protected data."
    end

    rows = [
      date_received? ? { key: { text: "Received date" }, value: { text: date_received.strftime("%e %B %Y") } } : nil,
      received_type? ? { key: { text: "Received by" }, value: { text: received_type.upcase_first } } : nil,
      { key: { text: "Source type" }, value: { text: complainant.complainant_type } },
      { key: { text: "Contact details" }, value: { text: h.simple_format(contact_details.join("\n\n")) } }
    ]

    if complainant.can_be_displayed?
    end
    rows.compact!

    h.render "components/govuk_summary_list", rows: rows
  end

private

  def category
    @category ||= begin
      categories = [object.product_category]
      products.each { |product| categories << product.category }

      categories.compact.to_sentence(last_word_connector: " and ").downcase.upcase_first
    end
  end
end
