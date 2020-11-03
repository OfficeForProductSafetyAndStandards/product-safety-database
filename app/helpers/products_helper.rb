module ProductsHelper
  include SearchHelper

  SUGGESTED_PRODUCTS_LIMIT = 4

  # Never trust parameters from the scary internet, only allow the white list through.
  def product_params
    params.require(:product).permit(
      :brand, :name, :product_type, :category, :product_code, :webpage, :description, :batch_number, :country_of_origin, :gtin13, :authenticity
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

  # If the user supplies a barcode then just return that.
  # Otherwise use the general query param
  def advanced_product_search(product, excluded_ids = [])
    if product.product_code.present?
      search_for_product_code(product.product_code, excluded_ids)
    else
      possible_search_fields = {
        "name": product.name,
        "category": product.category
      }
      used_search_fields = possible_search_fields.reject { |_, value| value.blank? }
      fuzzy_match = used_search_fields.map do |field, value|
        {
          match: {
            "#{field}": {
              query: value,
              fuzziness: "AUTO"
            }
          }
        }
      end
      Product.search(query: {
        bool: {
          should: fuzzy_match,
          must_not: have_excluded_id(excluded_ids)
        }
      })
        .paginate(per_page: SUGGESTED_PRODUCTS_LIMIT)
        .records
    end
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

  def items_for_authenticity(form)
    items = [
      { text: "Yes",    value: :counterfeit },
      { text: "No",     value: :genuine },
      { text: "Unsure", value: :unsure },
    ]
    items << { text: "Not provided", value: :missing } if form.object.authenticity.nil?
    items
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
