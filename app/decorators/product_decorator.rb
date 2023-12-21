class ProductDecorator < ApplicationDecorator
  include FormattedDescription
  delegate_all
  decorates_association :investigations

  def name_with_brand
    [brand, name].compact.join(" ")
  end

  def subcategory_with_brand
    [subcategory, brand].compact.join(" by ")
  end

  def pretty_description
    "Product: #{name}"
  end

  def unformatted_description
    # Bypasses `FormattedDescription` for situations where
    # we want the raw value of the field.
    description
  end

  def details_list(date_case_closed: nil)
    timestamp = date_case_closed.to_i if date_case_closed
    psd_ref_key_html = '<abbr title="Product Safety Database">PSD</abbr> <span title="reference">ref</span>'.html_safe
    psd_secondary_text_html = if date_case_closed.present?
                                " - The <abbr>PSD</abbr> reference number for this version of the product record - as recorded when the notification was closed: #{date_case_closed.to_formatted_s(:govuk)}."
                              else
                                " - The <abbr>PSD</abbr> reference number for this product record"
                              end.html_safe
    webpage_html = "<span class='govuk-!-font-size-16'>#{webpage}</span>".html_safe
    when_placed_on_market_value = when_placed_on_market == "unknown_date" ? nil : when_placed_on_market
    psd_ref_value_html = date_case_closed.present? ? psd_ref(timestamp:, investigation_was_closed: true) : psd_ref(timestamp:, investigation_was_closed: false)

    rows = [
      { key: { text: psd_ref_key_html }, value: { text: "#{psd_ref_value_html}#{psd_secondary_text_html}" } },
      { key: { text: "Brand name" }, value: { text: object.brand } },
      { key: { text: "Product name" }, value: { text: object.name } },
      { key: { text: "Category" }, value: { text: category } },
      { key: { text: "Subcategory" }, value: { text: subcategory } },
      { key: { text: "Barcode" }, value: { text: barcode } },
      { key: { text: "Description" }, value: { text: description } },
      { key: { text: "Webpage" }, value: { text: webpage_html } },
      { key: { text: "Market date" }, value: { text: when_placed_on_market_value } },
      { key: { text: "Country of origin" }, value: { text: country_from_code(country_of_origin) } },
      { key: { text: "Counterfeit" }, value: counterfeit_row_value },
      { key: { text: "Product marking" }, value: { text: markings } },
      { key: { text: "Other product identifiers" }, value: { text: product_code } },
    ]

    h.govuk_summary_list(rows:)
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
    object.investigations.map(&:pretty_id).uniq
  end

  def counterfeit_row_value
    if product.counterfeit?
      return { text: "<span class=\"opss-tag opss-tag--risk2 opss-tag--lrg\">Yes</span> - #{counterfeit_explanation}".html_safe }
    end

    if product.genuine?
      return { text: "No - #{counterfeit_explanation}" }
    end

    { text: I18n.t(object.authenticity || :missing, scope: Product.model_name.i18n_key) }
  end

  def counterfeit_value
    return "Unsure" if product.unsure?

    product.counterfeit? ? "<span class='opss-tag opss-tag--risk2 opss-tag--lrg'>Yes</span>".html_safe : "No"
  end

  def counterfeit_explanation
    return if product.unsure?

    product.counterfeit? ? I18n.t("products.counterfeit") : I18n.t("products.genuine")
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

  def overview_summary_list
    rows = [
      {
        key: { text: "Last updated" },
        value: { text: h.date_or_recent_time_ago(product.updated_at) }
      },
      {
        key: { text: "Created" },
        value: { text: h.date_or_recent_time_ago(product.created_at) }
      }
    ]

    unless product.retired?
      rows << {
        key: { text: "Product record owner" },
        value: { html: owning_team_link }
      }
    end

    h.govukSummaryList(
      classes: "govuk-summary-list govuk-summary-list--no-border govuk-!-margin-bottom-4 opss-summary-list-mixed opss-summary-list-mixed--compact",
      rows:
    )
  end

  def product_name_with_cases
    rows = [
      {
        key: { text: "Product" },
        value: { text: "#{name_with_brand} <span class='govuk-!-font-weight-regular govuk-!-font-size-16 govuk-!-padding-left-2 opss-no-wrap'>(psd-#{id})</span>".html_safe }
      }
    ]

    if object.investigations.any?
      object.investigations.each_with_index do |investigation, i|
        rows << {
          key: { text: i.zero? ? "Notification(s)" : "" },
          value: { text: "#{investigation.user_title} <span class='govuk-!-font-weight-regular govuk-!-font-size-16 govuk-!-padding-left-2 opss-no-wrap'>(#{investigation.pretty_id})</span>".html_safe }
        }
      end
    end

    h.govukSummaryList(
      classes: "govuk-summary-list govuk-summary-list--no-border",
      rows:
    )
  end
end
