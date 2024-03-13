module ProductsHelper
  NOTIFICATION_TYPES = %i[allegation enquiry project notification].freeze

  def search_for_products(user = current_user, for_export: false)
    query = Product.includes(child_records(for_export))

    if @search.q.present?
      @search.q.strip!
      query = query.where("products.name ILIKE ?", "%#{@search.q}%")
        .or(Product.where("products.description ILIKE ?", "%#{@search.q}%"))
        .or(Product.where("products.brand ILIKE ?", "%#{@search.q}%"))
        .or(Product.where("products.product_code ILIKE ?", "%#{@search.q}%"))
        .or(Product.where("CONCAT('psd-', products.id) = LOWER(?)", @search.q))
        .or(Product.where(id: @search.q))
    end

    query = query.where(category: @search.category) if @search.category.present?

    query = query.where(investigations: { is_closed: false }) if @search.case_status == "open_only"

    query = query.where(retired_at: nil) if @search.retired_status == "active" || @search.retired_status.blank?

    query = query.where.not(retired_at: nil) if @search.retired_status == "retired"

    query = query.where(country_of_origin: @search.countries&.compact_blank) if @search.countries && !@search.countries.compact_blank.empty?

    notification_types = NOTIFICATION_TYPES.map { |type| "Investigation::#{type.capitalize}" if @search.send(type) }.compact

    query = query.where(investigations: { type: notification_types }) unless notification_types.empty?

    case @search.case_owner
    when "me"
      query = query.where(users: { id: user.id })
    when "my_team"
      team = user.team
      query = query.where(users: { id: team.users.map(&:id) }, teams: { id: team.id })
    end

    return query if for_export

    pagy(query.order(sorting_params))
  end

  # API searches on barcode instead of free text fields like description
  def api_search_for_products(user = current_user)
    query = Product.includes(child_records(false))
    query = query.where("products.name ILIKE ?", "%#{@search.name}%") if @search.name
    query = query.where("products.barcode = ?", @search.barcode) if @search.barcode
    query = query.where("products.product_code ILIKE ?", "%#{@search.product_code}%") if @search.product_code
    query = query.where(id: @search.id) if @search.id

    query = query.where(category: @search.category) if @search.category.present?

    query = query.where(investigations: { is_closed: false }) if @search.case_status == "open_only"

    query = query.where(retired_at: nil) if @search.retired_status == "active" || @search.retired_status.blank?

    query = query.where.not(retired_at: nil) if @search.retired_status == "retired"

    case @search.case_owner
    when "me"
      query = query.where(users: { id: user.id })
    when "my_team"
      team = user.team
      query = query.where(users: { id: team.users.map(&:id) }, teams: { id: team.id })
    end

    pagy(query.order(sorting_params))
  end

  def product_export_params
    params.permit(:q, :category, :notification, :allegation, :enquiry, :project, countries: [])
  end

  def child_records(for_export)
    return [:investigations, :owning_team, { investigation_products: [:test_results, { corrective_actions: [:business], risk_assessments: %i[assessed_by_business assessed_by_team] }] }] if for_export

    { investigations: %i[owner_user owner_team] }
  end

  def sorting_params
    return {} if params[:sort_by] == SortByHelper::SORT_BY_RELEVANT
    return { name: :desc } if params[:sort_by] == SortByHelper::SORT_BY_NAME && params[:sort_dir] == SortByHelper::SORT_DIRECTION_DESC
    return { name: :asc } if params[:sort_by] == SortByHelper::SORT_BY_NAME

    { created_at: :desc }
  end

  def sort_direction
    SortByHelper::SORT_DIRECTIONS.include?(sort_direction_param) ? sort_direction_param : :desc
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
      { text: "Yes", value: "counterfeit" },
      { text: "No", value: "genuine" },
      { text: "Unsure", value: "unsure" }
    ]

    return items if product_form.authenticity.blank?

    set_selected_authenticity_option(items, product_form)
  end

  def items_for_before_2021_radio(product_form)
    items = [
      { text: "Yes", value: "before_2021" },
      { text: "No", value: "on_or_after_2021" },
      { text: "Unable to ascertain", value: "unknown_date" }
    ]
    return items if product_form.when_placed_on_market.blank?

    set_selected_when_placed_on_market_option(items, product_form)
  end

  def options_for_country_of_origin(countries, product_form)
    options = [{ text: "Unknown", value: "Unknown" }]
    options << countries.map do |country|
      text = country[0]
      option = { text:, value: country[1] }
      option[:selected] = true if product_form.country_of_origin == text
      option
    end
    options.flatten
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
end
