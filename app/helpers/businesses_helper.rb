module BusinessesHelper
  def defaults_on_primary_location(business)
    business.primary_location.name ||= "Registered office address"
    business.primary_location.added_by_user = current_user
    business
  end

  def search_for_businesses(page_size = Business.count, user = current_user)
    query = Business.includes(investigations: %i[owner_user owner_team])

    if @search.q
      @search.q.strip!
      query = query.where("trading_name ILIKE ?", "%#{@search.q}%")
        .or(Business.where("legal_name ILIKE ?", "%#{@search.q}%"))
        .or(Business.where(company_number: @search.q))
    end

    if @search.case_status == "open_only"
      query = query.where(investigations: { is_closed: false })
    end

    case @search.case_owner
    when "me"
      query = query.where(users: { id: user.id })
    when "my_team"
      team = user.team
      query = query.where(users: { id: team.users.map(&:id) }, teams: { id: team.id })
    end

    query
      .order(sorting_params)
      .page(page_number)
      .per(page_size)
  end

  def business_export_params
    params.permit(:q)
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
