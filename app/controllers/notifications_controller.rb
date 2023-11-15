class NotificationsController < ApplicationController
  include InvestigationsHelper
  include BreadcrumbHelper

  before_action :set_search_params, only: %i[index]
  before_action :set_last_case_view_cookie, only: %i[index]

  breadcrumb "cases.label", :your_cases_investigations

  # GET /cases
  def index
    redirect_to all_cases_investigation_path unless current_user.can_access_new_search?

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

  def default_params
    params["case_statuses"] == %w[open closed] && params[:q].blank?
  end
end
