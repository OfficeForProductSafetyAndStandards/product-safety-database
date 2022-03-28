module ProductSearchHelper
  include SearchHelper

  def filter_params(user)
    filters_to_apply = [
      get_hazard_filter,
      get_owner_filter(user)
    ].compact

    { must: filters_to_apply }
  end

  def get_hazard_filter
    if params[:hazard_type].present?
      { match: { "investigations.hazard_type" => @search.hazard_type } }
    end
  end

  def get_owner_filter(user)
    byebug
    return if @search.case_owner == "all"
    # return { bool: { should: [], must_not: [] } } if @search.case_owner == "all"
    # return { bool: { should: [], must_not: compute_excluded_terms(user) } } if @search.case_owner == "others" && @search.case_owner_is_someone_else_id.blank?
    if @search.case_owner == "me"
      { match: { "investigations.owner_id" => user.id } }
    end
  end

  def compute_excluded_terms(user)
    format_owner_terms([user.id])
  end

  def compute_included_terms(user)
    owners = []

    case @search.case_owner
    when "me"
      owners << user.id
    when "my_team"
      owners += user_ids_from_team(user.team)
    when "others"
      owners += other_owner_ids
    end

    format_owner_terms(owners.uniq)
  end

  def format_owner_terms(owner_array)
    owner_array.map do |a|
      { term: { "investigations.owner_id" => a } }
    end
  end
end
