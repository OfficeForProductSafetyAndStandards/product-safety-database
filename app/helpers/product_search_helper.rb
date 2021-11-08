module ProductSearchHelper
  include SearchHelper

  def filter_params(_user)
    if params[:hazard_type].present?
      { must: [{ match: { "investigations.hazard_type" => @search.hazard_type } }] }
    end
  end
end
