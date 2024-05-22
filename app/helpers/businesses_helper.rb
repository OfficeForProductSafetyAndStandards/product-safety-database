module BusinessesHelper
  def defaults_on_primary_location(business)
    business.primary_location.name ||= "Registered office address"
    business.primary_location.added_by_user = current_user
    business
  end

  def search_for_businesses(user = current_user, for_export: false)
    query = initialize_business_query(for_export)

    query = filter_by_search(query) if @search.q.present?
    query = filter_by_case_status(query)
    query = filter_by_business_types(query)
    query = filter_by_selected_countries(query)
    query = filter_by_case_owner(query, user)

    query = distinct_by_name_and_number(query)

    for_export ? query : pagy(query.order(sorting_params))
  end

private

  def initialize_business_query(for_export)
    Business.without_online_marketplaces.includes(child_records(for_export))
  end

  def filter_by_search(query)
    search_term = @search.q.strip
    query.where("trading_name ILIKE :term OR legal_name ILIKE :term OR company_number = :term", term: "%#{search_term}%")
  end

  def filter_by_case_status(query)
    return query unless @search.case_status == "open_only"

    query.where(investigations: { is_closed: false })
  end

  def filter_by_business_types(query)
    business_types = Business::BUSINESS_TYPES.select { |type| @search.send(type) }
    business_types.empty? ? query : query.where(investigation_businesses: { relationship: business_types })
  end

  def filter_by_selected_countries(query)
    selected_countries = Country.all.select { |country| @search.send(country[0].parameterize.underscore) }.map { |country| country[1] }
    return query if selected_countries.empty?

    primary_location_ids = Business.all.map(&:primary_location).compact.pluck(:id)
    query.where(locations: { id: primary_location_ids, country: selected_countries })
  end

  def filter_by_case_owner(query, user)
    case @search.case_owner
    when "me"
      query.where(users: { id: user.id })
    when "my_team"
      team = user.team
      query.where(users: { id: team.users.map(&:id) }, teams: { id: team.id })
    else
      query
    end
  end

  def distinct_by_name_and_number(query)
    subquery = query.select("MIN(businesses.id) as id")
                    .group("businesses.trading_name, businesses.company_number")
    Business.where(id: subquery)
  end

  def child_records(for_export)
    for_export ? %i[investigations locations contacts] : [:online_marketplace, :locations, { investigations: %i[owner_user owner_team] }]
  end

  def business_export_params
    params.permit(:q, *Business::BUSINESS_TYPES.map(&:to_sym), *country_params)
  end

  def country_params
    Country.all.map { |country| country[0].parameterize.underscore.to_sym }
  end

  def sorting_params
    case params[:sort_by]
    when SortByHelper::SORT_BY_RELEVANT
      {}
    when SortByHelper::SORT_BY_NAME
      { trading_name: params[:sort_dir] == SortByHelper::SORT_DIRECTION_DESC ? :desc : :asc }
    else
      { created_at: :desc }
    end
  end

  def sort_column
    Business.column_names.include?(params[:sort_by]) ? params[:sort_by] : :created_at
  end

  def sort_direction
    SortByHelper::SORT_DIRECTIONS.include?(params[:sort_dir]) ? params[:sort_dir] : :desc
  end

  def business_params
    params.require(:business).permit(
      :legal_name, :trading_name, :company_number,
      locations_attributes: %i[id name address_line_1 address_line_2 phone_number city county country postal_code],
      contacts_attributes: %i[id name email phone_number job_title]
    )
  end

  def set_business
    @business = Business.find(params[:id])
  end
end
