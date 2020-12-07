module ProductsHelper
  include SearchHelper

  SUGGESTED_PRODUCTS_LIMIT = 4

  # Never trust parameters from the scary internet, only allow the white list through.
  def product_params
    params.require(:product).permit(
      :brand, :name, :subcategory, :category, :product_code, :webpage, :description, :batch_number, :country_of_origin, :gtin13, :authenticity, :affected_units_status, :number_of_affected_units, :exact_units, :approx_units
    )
  end

  def search_for_products(page_size)
    ProductDecorator.decorate_collection(
      Product.full_search(search_query)
        .page(params[:page]).per_page(page_size).records
    )
  end

  def sorting_params
    return {} if params[:sort] == SearchParams::RELEVANT

    { created_at: :desc }
  end

  def search_for_product_code(product_code, excluded_ids)
    match_product_code = { match: { product_code: product_code } }
    Product.search(query: {
      bool: {
        must: match_product_code,
        must_not: have_excluded_id(excluded_ids),
      }
    })
      .paginate(per_page: SUGGESTED_PRODUCTS_LIMIT)
      .records
  end

  def set_countries
    @countries = all_countries
  end

  def set_product
    @product = Product.find(params[:id]).decorate
  end

  def items_for_authenticity(product_form)
    items = [
      { text: "Yes",    value: "counterfeit" },
      { text: "No",     value: "genuine" },
      { text: "Unsure", value: "unsure" },
    ]

    return items if product_form.authenticity.blank?

    set_selected_authenticity_option(items, product_form)
  end

  def items_for_affected_units(product_form, form)
    items = [
      { text: "Exact number known",       value: "exact", conditional: { html: form.govuk_input(:exact_units, label: "How many units?") } },
      { text: "Approximate number known", value: "approx", conditional: { html: form.govuk_input(:approx_units, label: "How many units?") } },
      { text: "Unknown",                  value: "unknown" },
      { divider: "or" },
      { text: "Not relevant", value: "not_relevant" }
    ]

    return items if product_form.affected_units_status.blank?

    set_affected_selected_units_status_option(items, product_form)
  end

  def options_for_country_of_origin(countries, product_form)
    countries.map do |country|
      text = country[0]
      option = { text: text, value: country[1] }
      option[:selected] = true if product_form.country_of_origin == text
      option
    end
  end

private

  def set_selected_authenticity_option(items, product_form)
    items.each do |item|
      next if skip_selected_item_for_selected_option?(item, product_form)

      item[:selected] = true if authenticity_selected?(item, product_form)
    end
  end

  def set_affected_selected_units_status_option(items, product_form)
    items.each do |item|
      next if skip_selected_item_for_selected_option?(item, product_form)

      item[:selected] = true if affected_units_status_selected?(item, product_form)
    end
  end

  def authenticity_selected?(item, product_form)
    item[:value] == product_form.authenticity
  end

  def affected_units_status_selected?(item, product_form)
    item[:value] == product_form.affected_units_status
  end

  def skip_selected_item_for_selected_option?(item, product_form)
    item[:divider] || item[:value].inquiry.missing? && product_form.id.nil?
  end

  def have_excluded_id(excluded_ids)
    {
      ids: {
        values: excluded_ids.map(&:to_s)
      }
    }
  end

  def build_breadcrumb_structure
    {
      items: [
        {
          text: "Products",
          href: products_path
        },
        {
          text: @product.name
        }
      ]
    }
  end
end
