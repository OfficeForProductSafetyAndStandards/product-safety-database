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
        count: " (#{@investigation.products.size})",
        active: is_current_tab.products?
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
    sanitized_content = sanitize(result, tags: %w[em])
    sanitized_content.html_safe
  end

  def gdpr_restriction_text
    "GDPR protected details hidden"
  end

  def should_be_hidden(result, source, investigation)
    return true if correspondence_should_be_hidden(result, source, investigation)
    return true if (source.include? "complainant") && !investigation&.complainant&.can_be_displayed?(current_user)

    false
  end

  def correspondence_should_be_hidden(result, source, investigation)
    return false unless source.include? "correspondences"

    key = source.partition(".").last
    sanitized_content = sanitize(result, tags: [])

    # If a result in its entirety appears in case correspondence that the user can see,
    # we probably don't care what was its source.
    investigation.correspondences.each do |c|
      return false if (c.send(key)&.include? sanitized_content) && c.can_be_displayed?(current_user)
    end
    true
  end

  def investigation_owner(investigation)
    return "No case owner".html_safe unless investigation.owner

    owner_names = [h(investigation.owner.name.to_s)]
    owner_names << h(investigation.owner_team&.name)
    # Team name can be the same as owner name
    owner_names.uniq!
    owner_names.compact!

    safe_join(owner_names, "<br>".html_safe)
  end

  def business_summary_list(business)
    rows = [
      { key: { text: "Trading name" }, value: { text: business.trading_name } },
      { key: { text: "Registered or legal name" }, value: { text: business.legal_name } },
      { key: { text: "Company number" }, value: { text: business.company_number } },
      { key: { text: "Address" }, value: { text: business.primary_location&.summary } },
      { key: { text: "Contact" }, value: { text: business.primary_contact&.summary } }
    ]

    # TODO: PSD-693 Add primary authorities to businesses
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
