class NotificationsController < ApplicationController
  include InvestigationsHelper
  include BreadcrumbHelper

  before_action :set_search_params, only: %i[index]
  before_action :set_investigation, only: %i[show created cannot_close confirm_deletion destroy]
  before_action :set_last_case_view_cookie, only: %i[index your_cases assigned_cases team_cases]

  breadcrumb "cases.label", :your_cases_investigations

  # GET /cases
  def index
    respond_to do |format|
      format.html do
        @answer         = new_opensearch_for_investigations(20)
        @count          = count_to_display
        @investigations = InvestigationDecorator
                            .decorate_collection(@answer.includes([{ owner_user: :organisation, owner_team: :organisation }, :products]))
        @page_name = "all_cases"
      end
    end
  end

  # GET /cases/1
  def show
    authorize @investigation, :view_non_protected_details?
    breadcrumb breadcrumb_case_label, breadcrumb_case_path
    @complainant = @investigation.complainant&.decorate
  end

  def created
    authorize @investigation, :view_non_protected_details?
  end

private

  def set_last_case_view_cookie
    cookies[:last_case_view] = params[:action]
  end

  def count_to_display
    default_params ? Investigation.not_deleted.count : @answer.total_count
  end

  def set_search_params
    @search = SearchParams.new(query_params.except(:page_name))
  end

  def set_investigation
    investigation = Investigation.includes(:owner_team, :owner_user, :products, :teams_with_access).find_by!(pretty_id: params[:pretty_id])
    @investigation = investigation.decorate
  end

  def default_params
    [params[:case_owner], params[:case_type], params[:created_by], params[:priority], params[:teams_with_access], params[:hazard_type], params[:created_from_date], params[:created_to_date]].each do |param_value|
      return false unless param_value == "all" || param_value.blank?
    end

    params["case_statuses"] == ["open", "closed"] && params[:q].blank?
  end
end
