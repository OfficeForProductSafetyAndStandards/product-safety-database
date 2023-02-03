class ProductDecorator < ApplicationDecorator
  include FormattedDescription
  delegate_all
  decorates_association :investigations

  def name_with_brand
    [brand, name].compact.join(" ")
  end

  def pretty_description
    "Product: #{name}"
  end

  def details_list(date_case_closed: nil)
    timestamp = date_case_closed.to_i if date_case_closed
    psd_ref_key_html = '<abbr title="Product Safety Database">PSD</abbr> <span title="reference">ref</span>'.html_safe
    psd_secondary_text_html = '<span class="govuk-visually-hidden"> - </span>The <abbr>PSD</abbr> reference for this version of the product record'.html_safe
    psd_secondary_text_html << " - as recorded when the case was closed: #{date_case_closed.to_formatted_s(:govuk)}.".html_safe if date_case_closed.present?
    webpage_html = "<span class='govuk-!-font-size-16'>#{webpage}</span>".html_safe
    when_placed_on_market_value = when_placed_on_market == "unknown_date" ? nil : when_placed_on_market
    psd_ref_value_html = h.safe_join([psd_ref(timestamp:, investigation_was_closed: date_case_closed.present?), "<br>".html_safe])

    rows = [
      { key: { html: psd_ref_key_html }, value: { html: psd_ref_value_html, secondary_text: { html: psd_secondary_text_html } } },
      { key: { text: "Brand name" }, value: { text: object.brand } },
      { key: { text: "Product name" }, value: { text: object.name } },
      { key: { text: "Category" }, value: { text: category } },
      { key: { text: "Subcategory" }, value: { text: subcategory } },
      { key: { text: "Barcode" }, value: { text: barcode } },
      { key: { text: "Description" }, value: { text: description } },
      { key: { text: "Webpage" }, value: { html: webpage_html } },
      { key: { text: "Market date" }, value: { text: when_placed_on_market_value }, secondary_text: { text: "Placed on the market" } },
      { key: { text: "Country of origin" }, value: { text: country_from_code(country_of_origin) } },
      { key: { text: "Counterfeit" }, value: counterfeit_row_value },
      { key: { text: "Product marking" }, value: { text: markings } },
      { key: { text: "Other product identifiers" }, value: { text: product_code } },
    ]

    h.govukSummaryList classes: "opss-summary-list-mixed opss-summary-list-mixed--narrow-dt", rows:
  end

  def summary_list(timestamp = nil)
    psd_ref_key_html = "<abbr title='Product Safety Database'>PSD</abbr> <span title='reference'>ref</span>".html_safe
    psd_secondary_text_html = "<span class='govuk-visually-hidden'> - </span>The <abbr>PSD</abbr> reference for this product record".html_safe
    rows = [
      { key: { html: psd_ref_key_html }, value: { text: psd_ref(timestamp:, investigation_was_closed: timestamp.present?), secondary_text: { html: psd_secondary_text_html } } },
      { key: { text: "Category" }, value: { text: category } },
      { key: { text: "Product subcategory" }, value: { text: subcategory } },
      { key: { text: "Product authenticity" }, value: { text: authenticity } },
      { key: { text: "Product marking" }, value: { text: markings } },
      { key: { text: "Product brand" }, value: { text: object.brand } },
      { key: { text: "Product name" }, value: { text: object.name } },
      { key: { text: "When placed on market" }, value: { text: when_placed_on_market } },
      { key: { text: "Barcode number" }, value: { text: barcode } },
      { key: { text: "Other product identifiers" }, value: { text: product_code } },
      { key: { text: "Webpage" }, value: { text: object.webpage } },
      { key: { text: "Description" }, value: { text: description } },
      { key: { text: "Country of origin" }, value: { text: country_from_code(country_of_origin) } },
    ]
    rows.compact!
    h.govukSummaryList rows:, classes: "govuk-!-margin-top-8 opss-summary-list-mixed opss-summary-list-mixed--narrow-dt opss-summary-list-mixed--narrow-actions"
  end

  def authenticity
    I18n.t(object.authenticity || :missing, scope: Product.model_name.i18n_key)
  end

  def when_placed_on_market
    case object.when_placed_on_market
    when "before_2021"
      I18n.t(".product.before_2021")
    when "on_or_after_2021"
      I18n.t(".product.on_or_after_2021")
    when "unknown_date"
      I18n.t(".product.unknown_date")
    else
      I18n.t(".product.not_provided")
    end
  end

  def subcategory_and_category_label
    product_and_category = [subcategory.presence, category.presence].compact

    if product_and_category.length > 1
      "#{product_and_category.first} (#{product_and_category.last.downcase})"
    else
      product_and_category.first
    end
  end

  def markings
    return I18n.t(".product.not_provided") unless object.has_markings
    return I18n.t(".product.unknown") if object.markings_unknown?
    return I18n.t(".product.none") if object.markings_no?

    object.markings.join(", ")
  end

  def case_ids
    object.investigations.map(&:pretty_id)
  end

  def counterfeit_row_value
    if product.counterfeit?
      return { html: "<span class='opss-tag opss-tag--risk2 opss-tag--lrg'>Yes</span>".html_safe, secondary_text: { text: "This is a product record for a counterfeit product" } }
    end

    if product.genuine?
      return { text: "No", secondary_text: { text: "This product record is about a genuine product" } }
    end

    { text: I18n.t(object.authenticity || :missing, scope: Product.model_name.i18n_key) }
  end

  def counterfeit_value
    return "Unsure" if product.unsure?

    product.counterfeit? ? "<span class='opss-tag opss-tag--risk2 opss-tag--lrg'>Yes</span>".html_safe : "No"
  end

  def activity_view_link(timestamp)
    object.versions.count > 1 ? "/products/#{object.id}/#{timestamp}" : Rails.application.routes.url_helpers.product_path(object)
  end

  def owning_team_text
    return "No owner" if owning_team.nil?
    return "Your team is the product record owner" if owning_team == h.current_user.team

    owning_team.name
  end

  def owning_team_link
    return "No owner" if owning_team.nil?
    return "Your team is the product record owner" if owning_team == h.current_user.team

    h.link_to owning_team.name, h.owner_product_path(object), class: "govuk-link govuk-link--no-visited-state"
  end

  def unique_cases_except(investigation)
    unique_investigations = unique_investigation_products.map { |investigation_product| investigation_product.investigation unless investigation_product.investigation.id == investigation.id }

    unique_investigations.compact.sort_by(&:created_at).reverse!
  end

  def overview_summary_list(link_to_owner: true)
    h.govukSummaryList(
      classes: "govuk-summary-list govuk-summary-list--no-border govuk-!-margin-bottom-4 opss-summary-list-mixed opss-summary-list-mixed--compact",
      rows: [
        {
          key: { text: "Last updated" },
          value: { text: h.date_or_recent_time_ago(product.updated_at) }
        },
        {
          key: { text: "Created" },
          value: { text: h.date_or_recent_time_ago(product.created_at) }
        },
        {
          key: { text: "Product record owner" },
          value: link_to_owner ? { html: owning_team_link } : { text: owning_team_text }
        }
      ]
    )
  end
end
