module BusinessesHelper
  def defaults_on_primary_location(business)
    business.primary_location.name ||= "Registered office address"
    business.primary_location.added_by_user = current_user
    business
  end

  def search_for_businesses(user = current_user, for_export: false)
    query = Business.without_online_marketplaces.includes(child_records(for_export))

    if @search.q.present?
      @search.q.strip!
      query = query.where("trading_name ILIKE ?", "%#{@search.q}%")
        .or(Business.where("legal_name ILIKE ?", "%#{@search.q}%"))
        .or(Business.where(company_number: @search.q))
    end

    query = query.where(investigations: { is_closed: false }) if @search.case_status == "open_only"

    business_types = []

    Business::BUSINESS_TYPES.each do |business_type|
      business_types << business_type if @search.send(business_type)
    end

    query = query.where(investigation_businesses: { relationship: business_types }) unless business_types.empty?

    selected_countries = []

    Country.all.map do |country|
      selected_countries << country[1] if @search.send(country[0].parameterize.underscore)
    end

    unless selected_countries.empty?
      primary_location_ids = Business.all.map(&:primary_location).compact.pluck(:id)
      query = query.where(locations: { id: primary_location_ids, country: selected_countries })
    end

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

  def child_records(for_export)
    return %i[investigations locations contacts] if for_export

    [:online_marketplace, :locations, { investigations: %i[owner_user owner_team] }]
  end

  def business_export_params
    params.permit(:q, *Business::BUSINESS_TYPES.map(&:to_sym), *Country.all.map { |country| country[0].parameterize.underscore.to_sym })
  end

  def sorting_params
    return {} if params[:sort_by] == SortByHelper::SORT_BY_RELEVANT
    return { trading_name: :desc } if params[:sort_by] == SortByHelper::SORT_BY_NAME && params[:sort_dir] == SortByHelper::SORT_DIRECTION_DESC
    return { trading_name: :asc } if params[:sort_by] == SortByHelper::SORT_BY_NAME

    { created_at: :desc }
  end

  def sort_column
    Business.column_names.include?(params[:sort_by]) ? params[:sort_by] : :created_at
  end

  def sort_direction
    SortByHelper::SORT_DIRECTIONS.include?(params[:sort_dir]) ? params[:sort_dir] : :desc
  end

  def business_params
    params.require(:business).permit(
      :legal_name,
      :trading_name,
      :company_number,
      locations_attributes: %i[id name address_line_1 address_line_2 phone_number city county country postal_code],
      contacts_attributes: %i[id name email phone_number job_title]
    )
  end

  def set_business
    @business = Business.find(params[:id])
  end
end
