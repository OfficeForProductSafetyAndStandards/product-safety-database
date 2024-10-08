class ProductDecorator < ApplicationDecorator
  include FormattedDescription
  delegate_all
  decorates_association :investigations

  # Include the sanitize helper
  include ActionView::Helpers::SanitizeHelper

  # Safely combines the brand and name of the product
  def name_with_brand
    [sanitize(brand), sanitize(name)].compact.join(" ")
  end

  def pretty_description
    "Product: #{sanitize(name)}"
  end

  def unformatted_description
    object.description
  end

  def details_list(date_case_closed: nil)
    timestamp = date_case_closed.to_i if date_case_closed

    psd_ref_key_html = '<abbr title="Product Safety Database">PSD</abbr> <span title="reference">ref</span>'.html_safe
    psd_secondary_text_html = if date_case_closed.present?
                                " - The <abbr>PSD</abbr> reference number for this version of the product record - as recorded when the notification was closed: #{sanitize(date_case_closed.to_formatted_s(:govuk))}."
                              else
                                " - The <abbr>PSD</abbr> reference number for this product record"
                              end.html_safe

    webpage_html = "<span class='govuk-!-font-size-16'>#{sanitize(webpage.presence || '')}</span>".html_safe

    when_placed_on_market_value = when_placed_on_market == "unknown_date" ? nil : sanitize(when_placed_on_market.presence || "")

    psd_ref_value_html = date_case_closed.present? ? psd_ref(timestamp:, investigation_was_closed: true) : psd_ref(timestamp:, investigation_was_closed: false)

    rows = [
      { key: { text: psd_ref_key_html }, value: { text: "#{psd_ref_value_html}#{psd_secondary_text_html}".html_safe } },
      { key: { text: "Brand name" }, value: { text: sanitize(object.brand.presence || "") } },
      { key: { text: "Product name" }, value: { text: sanitize(object.name.presence || "") } },
      { key: { text: "Category" }, value: { text: sanitize(category.presence || "") } },
      { key: { text: "Subcategory" }, value: { text: sanitize(subcategory.presence || "") } },
      { key: { text: "Barcode" }, value: { text: sanitize(barcode.presence || "") } },
      { key: { text: "Description" }, value: { text: sanitize(description.presence || "") } },
      { key: { text: "Webpage" }, value: { text: webpage_html } }, # Already sanitized
      { key: { text: "Market date" }, value: { text: when_placed_on_market_value } },
      { key: { text: "Country of origin" }, value: { text: sanitize(country_from_code(country_of_origin.presence || "")) } },
      { key: { text: "Counterfeit" }, value: counterfeit_row_value }, # Assuming this is already safe
      { key: { text: "Product marking" }, value: { text: sanitize(markings.presence || "") } },
      { key: { text: "Other product identifiers" }, value: { text: sanitize(product_code.presence || "") } },
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
    product_and_category = [sanitize(subcategory.presence), sanitize(category.presence)].compact

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

    sanitize(object.markings.join(", "))
  end

  def case_ids
    object.investigations.map(&:pretty_id).uniq
  end

  def counterfeit_row_value
    if product.counterfeit?
      return { text: "<span class=\"opss-tag opss-tag--risk2 opss-tag--lrg\">Yes</span> - #{sanitize(counterfeit_explanation)}".html_safe }
    end

    if product.genuine?
      return { text: "No - #{sanitize(counterfeit_explanation)}" }
    end

    { text: I18n.t(object.authenticity || :missing, scope: Product.model_name.i18n_key) }
  end

  def counterfeit_value
    return "Unsure" if product.unsure?

    product.counterfeit? ? "<span class='opss-tag opss-tag--risk2 opss-tag--lrg'>Yes</span>".html_safe : "No"
  end

  def counterfeit_explanation
    return if product.unsure?

    sanitize(product.counterfeit? ? I18n.t("products.counterfeit") : I18n.t("products.genuine"))
  end

  def owning_team_link
    return "No owner" if owning_team.nil?
    return "Your team is the product record owner" if owning_team == h.current_user.team

    h.link_to sanitize(owning_team.name), h.owner_product_path(object), class: "govuk-link govuk-link--no-visited-state"
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
        value: { text: owning_team_link }
      }
    end

    h.govuk_summary_list(rows:, borders: false, classes: "govuk-!-margin-bottom-4 opss-summary-list-mixed opss-summary-list-mixed--compact")
  end

  def product_name_with_cases
    rows = [
      {
        key: { text: "Product" },
        value: { text: "#{sanitize(name_with_brand)} <span class='govuk-!-font-weight-regular govuk-!-font-size-16 govuk-!-padding-left-2 opss-no-wrap'>(psd-#{sanitize(id.to_s)})</span>".html_safe }
      }
    ]

    if object.investigations.any?
      object.investigations.each_with_index do |investigation, i|
        rows << {
          key: { text: i.zero? ? "Notification(s)" : "" },
          value: { text: "#{sanitize(investigation.user_title)} <span class='govuk-!-font-weight-regular govuk-!-font-size-16 govuk-!-padding-left-2 opss-no-wrap'>(#{sanitize(investigation.pretty_id)})</span>".html_safe }
        }
      end
    end

    h.govuk_summary_list(rows:, borders: false)
  end
end
