module BusinessesHelper
  include SearchHelper

  def defaults_on_primary_location(business)
    business.primary_location.name ||= "Registered office address"
    business.primary_location.source ||= UserSource.new(user: current_user)
    business
  end

  def search_for_businesses(page_size = Business.count)
    Business.full_search(search_query)
      .page(params[:page])
      .per_page(page_size)
      .records
  end

  def search_for_businesses_in_batches(size = 1000)
    businesses = []
    after = 0

    loop do
      query = search_after_query(search_query.build_query([], [], []), size, after)

      results = Business.search(query)
      results_amount = results.size
      businesses += results
      after += size

      break if results_amount.zero?
    end

    businesses
  end

  def business_export_params
    params.permit(:sort, :q)
  end

  def sorting_params
    return {} if params[:sort] == "relevance"

    { created_at: :desc }
  end

  def sort_column
    Business.column_names.include?(params[:sort]) ? params[:sort] : :created_at
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : :desc
  end

  def set_countries
    @countries = all_countries
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

  def create_business
    if params[:business]
      @business = Business.new(business_params)
      @business.locations.build unless @business.locations.any?
      defaults_on_primary_location(@business)
      @business.contacts.build unless @business.contacts.any?
      @business.source = UserSource.new(user: current_user)
    else
      @business = Business.new
      @business.locations.build
      @business.contacts.build
    end
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

  def search_after_query(_search_query, size, after)
    query.merge!({
      sort: [
        { id: "asc" }
      ],
      size: size,
      search_after: [after]
    })
  end
end
