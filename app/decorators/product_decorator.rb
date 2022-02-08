class ProductDecorator < ApplicationDecorator
  include FormattedDescription
  delegate_all
  decorates_association :investigations

  def pretty_description
    "Product: #{name}"
  end

  def summary_list
    # psd_ref_key_html = "<abbr title='Product Safety Database'>PSD</abbr> <span title='reference'>ref</span>"
    # psd_secondary_text_html = "<span class='govuk-visually-hidden'> - </span>The <abbr>PSD</abbr> reference for this product record"
    rows = [
      { field: "PSD (Product Safety Database) ref", value: psd_ref },
      { field: "Category", value: category },
      { field: "Product subcategory", value: subcategory },
      { field: "Product authenticity", value: authenticity },
      { field: "Product marking", value: markings },
      { field: "Units affected", value: units_affected },
      { field: "Product brand", value: object.brand },
      { field: "Product name", value: object.name },
      { field: "When placed on market", value: when_placed_on_market },
      { field: "Barcode number", value: barcode },
      { field: "Batch number", value: batch_number },
      { field: "Other product identifiers", value: product_code },
      { field: "Webpage", value: object.webpage },
      { field: "Description", value: description },
      { field: "Country of origin", value: country_from_code(country_of_origin) },
      { field: "Customs code", value: object.customs_code }
    ]
    rows.compact!
    h.render "govuk_publishing_components/components/summary_list", items: rows
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

  def units_affected
    case object.affected_units_status
    when "exact"
      object.number_of_affected_units
    when "approx"
      object.number_of_affected_units
    when "unknown"
      I18n.t(".product.unknown")
    when "not_relevant"
      I18n.t(".product.not_relevant")
    else
      I18n.t(".product.not_provided")
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
end
