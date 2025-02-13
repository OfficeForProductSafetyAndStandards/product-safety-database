module Investigations::DisplayTextHelper
  def image_document_text(document)
    document.image? ? "image" : "document"
  end

  def investigation_sub_nav(investigation, current_tab: "overview")
    is_current_tab = ActiveSupport::StringInquirer.new(current_tab)
    investigation_business = investigation.businesses
    business_sub_items = investigation_business.map do |business|
      { text: business.trading_name, href: investigation_businesses_path(investigation, anchor: business.trading_name.parameterize) }
    end
    items = [
      {
        href: investigation_path(investigation),
        html: safe_join(["Notification ", tag.span(" #{investigation.pretty_id}", class: "govuk-!-font-weight-regular")]),
        text: "Notification",
        active: is_current_tab.overview?,
        sub_items: investigation_sub_items(investigation)
      },
      {
        href: investigation_products_path(investigation),
        text: "Products",
        count: " (#{investigation.products.size})",
        active: is_current_tab.products?,
        sub_items: products_sub_items(investigation)
      },
      {
        href: investigation_businesses_path(investigation),
        text: "Businesses",
        count: " (#{investigation.businesses.size})",
        active: is_current_tab.businesses?,
        sub_items: business_sub_items
      },
      {
        href: investigation_images_path(investigation),
        text: "Images",
        count: " (#{investigation.images.size + investigation.image_uploads.size})",
        active: is_current_tab.images?
      },
      {
        href: investigation_supporting_information_index_path(investigation),
        text: "Supporting information",
        count: " (#{investigation.supporting_information.size + investigation.generic_supporting_information_attachments.size})",
        active: is_current_tab.supporting_information?,
        sub_items: [
          {
            text: "Accidents and incidents",
            count: " (#{investigation.unexpected_events.size})",
            href: investigation_supporting_information_index_path(investigation, anchor: "accident-or-incidents")
          },
          {
            text: "Corrective actions",
            count: " (#{investigation.corrective_actions.size})",
            href: investigation_supporting_information_index_path(investigation, anchor: "corrective-actions")
          },
          {
            text: "Risk assessments",
            count: " (#{investigation.risk_assessments.size})",
            href: investigation_supporting_information_index_path(investigation, anchor: "risk-assessments")
          },
          {
            text: "PRISM risk assessments",
            count: " (#{investigation.prism_risk_assessments.submitted.size})",
            href: investigation_supporting_information_index_path(investigation, anchor: "prism-risk-assessments")
          },
          {
            text: "Correspondence",
            count: " (#{investigation.correspondences.size})",
            href: investigation_supporting_information_index_path(investigation, anchor: "correspondence")
          },
          {
            text: "Test results",
            count: " (#{investigation.test_results.size})",
            href: investigation_supporting_information_index_path(investigation, anchor: "test-results")
          },
          {
            text: "Other",
            count: " (#{investigation.generic_supporting_information_attachments.size})",
            href: investigation_supporting_information_index_path(investigation, anchor: "other")
          }
        ].compact
      },

      {
        href: investigation_activity_path(investigation),
        text: "Activity",
        active: is_current_tab.activity?
      }
    ]
    render "investigations/sub_nav", items:
  end

  def investigation_sub_items(investigation)
    rows = [
      {
        text: "Safety and compliance",
        href: investigation_path(investigation, anchor: "safety")
      },
      {
        text: "Notification specific product information",
        href: investigation_path(investigation, anchor: "product-info-1")
      }
    ]

    if investigation.complainant
      rows << {
        text: "Notification source",
        href: investigation_path(investigation, anchor: "source")
      }
    end

    rows
  end

  def products_sub_items(investigation)
    investigation.investigation_products.reverse.map do |investigation_product|
      {
        text: investigation_product.product.name,
        href: investigation_products_path(investigation_product.investigation, anchor: dom_id(investigation_product))
      }
    end
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
      content: protected_details_text(source, investigation)
    }

    highlight[1].each do |result|
      unless should_be_hidden?(source, investigation)
        best_highlight[:content] = get_highlight_content(source, result)
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
      pretty_id: "Notification number",
      "activities.search_index": "Activities, comment",
      "teams_with_access.id": "Team added to the notification"
    }
    pretty_field_names[field_name.to_sym] || field_name.humanize
  end

  def get_highlight_content(source, result)
    return get_highlighted_team_name(result) if source == "teams_with_access.id"

    sanitized_content = sanitize(result, tags: %w[em])
    sanitized_content.html_safe
  end

  def get_highlighted_team_name(highlighted_result)
    team_id = sanitize(highlighted_result, tags: [])
    team = Team.find(team_id)
    content_tag(:em, team.decorate.display_name).html_safe
  end

  def should_be_hidden?(source, investigation)
    (source.include?("complainant") || source.include?("correspondences")) &&
      !policy(investigation).view_protected_details?
  end

  def protected_details_text(source, _investigation)
    data_type = source.include?("correspondences") ? "correspondence" : "notification contact details"
    t("case.protected_details", data_type:)
  end

  def investigation_owner(investigation)
    return "No notification owner".html_safe unless investigation.owner

    owner_names = [h(investigation.owner.name.to_s)]
    owner_names << h(investigation.owner_team&.name)
    # Team name can be the same as owner name
    owner_names.uniq!
    owner_names.compact!

    safe_join(owner_names, " - ")
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

    govuk_summary_list(rows:)
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

    govuk_summary_list(rows:)
  end
end
