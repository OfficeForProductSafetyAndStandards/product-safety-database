module Investigations::DisplayTextHelper
  def image_document_text(document)
    document.image? ? "image" : "document"
  end

  def investigation_sub_nav(investigation, current_tab: "overview")
    is_current_tab = ActiveSupport::StringInquirer.new(current_tab)
    items = [
      {
        href: investigation_path(investigation),
        text: "Overview",
        active: is_current_tab.overview?
      },
      {
        href: investigation_products_path(investigation),
        text: "Products",
        count: " (#{@investigation.products.size})", active: is_current_tab.products?
      },
      {
        href: investigation_businesses_path(investigation),
        text: "Businesses",
        count: " (#{@investigation.businesses.size})",
        active: is_current_tab.businesses?
      },
      {
        href: investigation_attachments_path(investigation),
        text: "Attachments",
        count: " (#{@investigation.documents.size})",
        active: is_current_tab.attachments?
      },
      {
        href: investigation_activity_path(@investigation),
        text: "Activity",
        active: is_current_tab.activity?
      }
    ]
    render "investigations/sub_nav", items: items
  end

  def get_displayable_highlights(highlights, investigation)
    highlights.map do |highlight|
      get_best_highlight(highlight, investigation)
    end
  end

  def get_best_highlight(highlight, investigation)
    source = highlight[0]
    best_highlight = {
      label: pretty_source(source),
      content: gdpr_restriction_text
    }

    highlight[1].each do |result|
      unless should_be_hidden(result, source, investigation)
        best_highlight[:content] = get_highlight_content(result)
        return best_highlight
      end
    end

    best_highlight
  end

  def pretty_source(source)
    replace_unsightly_field_names(source).gsub(".", ", ")
  end

  def replace_unsightly_field_names(field_name)
    pretty_field_names = {
      pretty_id: "Case ID",
      "activities.search_index": "Activities, comment"
    }
    pretty_field_names[field_name.to_sym] || field_name.humanize
  end

  def get_highlight_content(result)
    sanitized_content = sanitize(result, tags: %w(em))
    sanitized_content.html_safe # rubocop:disable Rails/OutputSafety
  end

  def gdpr_restriction_text
    "GDPR protected details hidden"
  end

  def should_be_hidden(result, source, investigation)
    return true if correspondence_should_be_hidden(result, source, investigation)
    return true if (source.include? "complainant") && !investigation&.complainant&.can_be_displayed?

    false
  end

  def correspondence_should_be_hidden(result, source, investigation)
    return false unless source.include? "correspondences"

    key = source.partition(".").last
    sanitized_content = sanitize(result, tags: [])

    # If a result in its entirety appears in case correspondence that the user can see,
    # we probably don't care what was its source.
    investigation.correspondences.each do |c|
      return false if (c.send(key)&.include? sanitized_content) && c.can_be_displayed?
    end
    true
  end

  # rubocop:disable Rails/OutputSafety
  def investigation_assignee(investigation, classes = "")
    out = [investigation.assignee ? investigation.assignee.name.to_s : tag.div("Unassigned", class: classes)]
    out << tag.div(investigation.assignee.organisation.name, class: classes) if investigation.assignee&.organisation.present?
    out.join.html_safe
  end
  # rubocop:enable Rails/OutputSafety

  def business_summary_list(business)
    rows = [
      { key: { text: "Trading name" }, value: { text: business.trading_name } },
      { key: { text: "Registered or legal name" }, value: { text: business.legal_name } },
      { key: { text: "Company number" }, value: { text: business.company_number } },
      { key: { text: "Address" }, value: { text: business.primary_location&.summary } },
      { key: { text: "Contact" }, value: { text: business.primary_contact&.summary } }
    ]

    # TODO PSD-693 Add primary authorities to businesses
    # { key: { text: 'Primary authority' }, value: { text: 'Suffolk Trading Standards' } }

    render "components/govuk_summary_list", rows: rows
  end

  def correspondence_summary_list(correspondence, attachments: nil)
    rows = [
      { key: { text: "Call with" }, value: { text: get_call_with_field(correspondence) } },
      { key: { text: "Contains consumer info" }, value: { text: correspondence.has_consumer_info ? "Yes" : "No" } },
      { key: { text: "Summary" }, value: { text: correspondence.overview } },
      { key: { text: "Date" }, value: { text: correspondence.correspondence_date&.strftime("%d/%m/%Y") } },
      { key: { text: "Content" }, value: { text: correspondence.details } },
      { key: { text: "Attachments" }, value: { text: attachments } }
    ]

    render "components/govuk_summary_list", rows: rows
  end

  def investigation_summary_list(investigation, include_actions: false, classes: "")
    rows = [
      {
        key: { text: "Status", classes: classes },
        value: { text: investigation.status, classes: classes }
      },
      {
        key: { text: "Assigned to", classes: classes },
        value: { text: investigation_assignee(investigation, classes) }
      },
      {
        key: { text: "Last updated", classes: classes },
        value: { text: "#{time_ago_in_words(investigation.updated_at)} ago", classes: classes }
      }
    ]

    if include_actions
      rows[0][:actions] = [
        { href: status_investigation_path(investigation), text: "Change", classes: classes, visually_hidden_text: "status" }
      ]
      rows[1][:actions] = [
        { href: new_investigation_assign_path(investigation), text: "Change", classes: classes, visually_hidden_text: "assigned to" }
      ]
      rows[2][:actions] = [
        { href: new_investigation_activity_path(investigation), text: "Add activity", classes: classes, visually_hidden_text: "last updated" }
      ]
    end

    render "components/govuk_summary_list", rows: rows
  end

  def report_summary_list(investigation)
    rows = [
      { key: { text: "Date recorded" }, value: { text: investigation.created_at.strftime("%d/%m/%Y") } },
    ]
    if investigation.enquiry?
      rows << { key: { text: "Date received" }, value: { text: investigation.date_received? ? investigation.date_received.strftime("%d/%m/%Y") : "Not provided" } }
      rows << { key: { text: "Received by" }, value: { text: investigation.received_type? ? investigation.received_type.upcase_first : "Not provided" } }
    end

    if investigation.allegation?
      rows << { key: { text: "Product catgerory" }, value: { text: investigation.product_category } }
      rows << { key: { text: "Hazard type" }, value: { text: investigation.hazard_type } }
    end

    render "components/govuk_summary_list", rows: rows
  end
end
