class NotificationsController < ApplicationController
  include InvestigationsHelper
  include BreadcrumbHelper

  before_action :set_search_params, only: %i[index]
  before_action :set_last_case_view_cookie, only: %i[index]
  before_action :set_notification, except: %i[index]

  breadcrumb "cases.label", :your_cases_investigations

  # GET /notifications
  def index
    redirect_to all_cases_investigations_path unless current_user.can_access_new_search?

    respond_to do |format|
      format.html do
        @pagy, @answer  = pagy_searchkick(new_opensearch_for_investigations(20, paginate: true))
        @count          = count_to_display
        @investigations = InvestigationDecorator
                            .decorate_collection(@answer.includes([{ owner_user: :organisation, owner_team: :organisation }, :products]))
        @page_name = "all_cases"
      end
    end
  end

  # GET /notifications/:pretty_id
  def show; end

  # GET /notifications/:pretty_id/access
  def access; end

private

  def set_last_case_view_cookie
    cookies[:last_case_view] = params[:action]
  end

  def count_to_display
    default_params ? Investigation.not_deleted.count : @pagy.count
  end

  def set_search_params
    @search = SearchParams.new(query_params.except(:page_name))
  end

  def default_params
    params["case_statuses"] == %w[open closed] && params[:q].blank?
  end

  def set_notification
    @notification = Investigation::Notification.includes(:creator_user, :creator_team, :owner_user, :owner_team).find_by!(pretty_id: params[:pretty_id])
  end
end
