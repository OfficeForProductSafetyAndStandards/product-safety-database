module ProductsHelper
  include ProductSearchHelper

  SUGGESTED_PRODUCTS_LIMIT = 4
  PARAMS_FOR_CREATE = [:brand,
                       :name,
                       :subcategory,
                       :category,
                       :product_code,
                       :webpage,
                       :description,
                       :country_of_origin,
                       :barcode,
                       :authenticity,
                       :when_placed_on_market,
                       :has_markings,
                       { markings: [] }].freeze
  PARAMS_FOR_UPDATE = PARAMS_FOR_CREATE.without(:category, :authenticity,
                                                :brand, :name)

  # Never trust parameters from the scary internet, only allow the white list through.
  def product_params
    params.require(:product).permit(PARAMS_FOR_CREATE).with_defaults(markings: [])
  end

  def product_params_for_update
    params.require(:product).permit(PARAMS_FOR_UPDATE).with_defaults(markings: [])
  end

  def search_for_products(page_size = Product.count, user = current_user)
    Product.full_search(search_query(user))
      .page(page_number).per(page_size).records
  end

  def product_export_params
    params.permit(:q, :category)
  end

  def sorting_params
    return {} if params[:sort_by] == SortByHelper::SORT_BY_RELEVANT
    return { name_for_sorting: :desc } if params[:sort_by] == SortByHelper::SORT_BY_NAME && params[:sort_dir] == SortByHelper::SORT_DIRECTION_DESC
    return { name_for_sorting: :asc } if params[:sort_by] == SortByHelper::SORT_BY_NAME

    { created_at: :desc }
  end

  def sort_direction
    SortByHelper::SORT_DIRECTIONS.include?(params[:sort_dir]) ? params[:sort_dir] : :desc
  end

  def search_for_product_code(product_code, excluded_ids)
    match_product_code = { match: { product_code: } }
    Product.search(query: {
      bool: {
        must: match_product_code,
        must_not: have_excluded_id(excluded_ids),
      }
    })
      .page(1).per(SUGGESTED_PRODUCTS_LIMIT)
      .records
  end

  def set_product
    @product = Product.find(params[:id]).decorate
  end

  def conditionally_disabled_items_for_authenticity(product_form, disable_all_items: false)
    items = items_for_authenticity product_form
    return items unless disable_all_items

    items.map { |item| item.merge(disabled: true) }
  end

  def items_for_authenticity(product_form)
    items = [
      { text: "Yes",    value: "counterfeit" },
      { text: "No",     value: "genuine" }
    ]

    return items if product_form.authenticity.blank?

    set_selected_authenticity_option(items, product_form)
  end

  def items_for_before_2021_radio(product_form)
    items = [
      { text: "Yes",    value: "before_2021" },
      { text: "No",     value: "on_or_after_2021" },
      { text: "Unable to ascertain", value: "unknown_date" }
    ]
    return items if product_form.when_placed_on_market.blank?

    set_selected_when_placed_on_market_option(items, product_form)
  end

  def options_for_country_of_origin(countries, product_form)
    countries.map do |country|
      text = country[0]
      option = { text:, value: country[1] }
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

  def set_selected_when_placed_on_market_option(items, product_form)
    items.each do |item|
      next if skip_selected_item_for_selected_option?(item, product_form)

      item[:selected] = true if when_placed_on_market_option_selected?(item, product_form)
    end
  end

  def authenticity_selected?(item, product_form)
    item[:value] == product_form.authenticity
  end

  def when_placed_on_market_option_selected?(item, product_form)
    item[:value] == product_form.when_placed_on_market
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
end
