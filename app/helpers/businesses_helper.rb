module BusinessesHelper
  include BusinessSearchHelper

  def defaults_on_primary_location(business)
    business.primary_location.name ||= "Registered office address"
    business.primary_location.added_by_user = current_user
    business
  end

  def search_for_businesses(page_size = Business.count, user = current_user)
    Business.full_search(search_query(user))
      .page(page_number)
      .per(page_size)
      .records
  end

  def business_export_params
    params.permit(:q)
  end

  def sorting_params
    return {} if params[:sort_by] == SortByHelper::SORT_BY_RELEVANT
    return { name_for_sorting: :desc } if params[:sort_by] == SortByHelper::SORT_BY_NAME && params[:sort_dir] == SortByHelper::SORT_DIRECTION_DESC
    return { name_for_sorting: :asc } if params[:sort_by] == SortByHelper::SORT_BY_NAME

    { created_at: :desc }
  end

  def sort_column
    Business.column_names.include?(params[:sort_by]) ? params[:sort_by] : :created_at
  end

  def sort_direction
    SortByHelper::SORT_DIRECTIONS.include?(params[:sort_dir]) ? params[:sort_dir] : :desc
  end

  # Never trust parameters from the scary internet, only allow the white list through.
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

private

  def build_breadcrumb_structure
    {
      items: [
        {
          text: "Businesses",
          href: businesses_path
        },
        {
          text: @business.trading_name
        }
      ]
    }
  end
end
