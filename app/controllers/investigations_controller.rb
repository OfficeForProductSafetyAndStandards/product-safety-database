class InvestigationsController < ApplicationController
  include InvestigationsHelper
  include BreadcrumbHelper

  before_action :set_search_params, only: %i[index]
  before_action :set_investigation, only: %i[show created cannot_close confirm_deletion destroy]
  before_action :set_last_case_view_cookie, only: %i[index your_cases assigned_cases team_cases]

  breadcrumb "cases.label", :your_cases_investigations

  # GET /cases
  def index
    redirect_to notifications_path
  end

  # GET /cases/1
  def show
    return redirect_to notification_path(@investigation) if current_user.can_use_notification_task_list?

    authorize @investigation, :view_non_protected_details?
    breadcrumb breadcrumb_case_label, breadcrumb_case_path
    @complainant = @investigation.complainant&.decorate

    # Find the most recent incomplete bulk products upload for the current user and case, if any
    @incomplete_bulk_products_upload = BulkProductsUpload.where(user: current_user, submitted_at: nil, investigation: @investigation.object).order(updated_at: :desc).first
  end

  def created
    authorize @investigation, :view_non_protected_details?
  end

  def your_cases
    return redirect_to your_notifications_path if current_user.can_use_notification_task_list?

    @page_name = "your_cases"
    @search = SearchParams.new(
      {
        "case_owner" => "me",
        "sort_by" => params["sort_by"],
        "sort_dir" => params["sort_dir"],
        "page_name" => "your_cases"
      }
    )
    @pagy, @answer = search_for_investigations
    @count = @pagy.count
    @investigations = InvestigationDecorator
                        .decorate_collection(@answer.includes({ owner_user: :organisation, owner_team: :organisation }, :products))

    render "investigations/index"
  end

  def assigned_cases
    return redirect_to assigned_notifications_path if current_user.can_use_notification_task_list?

    @page_name = "assigned_cases"
    @search = SearchParams.new(
      {
        "case_owner" => "all",
        "teams_with_access" => "my_team",
        "created_by" => "others",
        "sort_by" => params["sort_by"],
        "sort_dir" => params["sort_dir"],
        "state" => "submitted",
        "page_name" => "assigned_cases"
      }
    )
    @pagy, @answer = search_for_investigations
    @count = @pagy.count
    @investigations = InvestigationDecorator
                        .decorate_collection(@answer.includes({ owner_user: :organisation, owner_team: :organisation }, :products))

    render "investigations/index"
  end

  def team_cases
    return redirect_to team_notifications_path if current_user.can_use_notification_task_list?

    @page_name = "team_cases"
    @search = SearchParams.new(
      {
        "case_owner" => "my_team",
        "sort_by" => params["sort_by"],
        "sort_dir" => params["sort_dir"],
        "state" => "submitted",
        "page_name" => "team_cases"
      }
    )
    @pagy, @answer = search_for_investigations
    @count = @pagy.count
    @investigations = InvestigationDecorator
                        .decorate_collection(@answer.includes({ owner_user: :organisation, owner_team: :organisation }, :products))

    render "investigations/index"
  end

  def cannot_close
    render "investigations/cannot_delete" unless Pundit.policy(current_user, @investigation).can_be_deleted?
  end

  def confirm_deletion
    render "investigations/cannot_delete" unless Pundit.policy(current_user, @investigation).can_be_deleted?
  end

  def destroy
    authorize @investigation, :change_owner_or_status?

    @delete_notification_form = DeleteNotificationForm.new(notification: @investigation)

    if @delete_notification_form.valid?
      DeleteNotification.call!(notification: @investigation, deleted_by: current_user)
      redirect_to your_cases_investigations_path, flash: { success: "The notification was deleted" }
    else
      redirect_to your_cases_investigations_path, flash: { warning: "The notification could not be deleted" }
    end
  end

private

  def set_search_params
    @search = SearchParams.new(query_params.except(:page_name))
  end

  def update!
    return unless request.patch?

    respond_to do |format|
      if @investigation.update(update_params)
        format.html do
          redirect_to investigation_path(@investigation),
                      flash: {
                        success: "Notification was successfully updated"
                      }
        end
        format.json { render :show, status: :ok, location: @investigation }
      else
        format.html { render action_name }
        format.json { render json: @investigation.errors, status: :unprocessable_entity }
      end
    end
  end

  def set_investigation
    investigation = Investigation.includes(:owner_team, :owner_user, :products, :teams_with_access).find_by!(pretty_id: params[:pretty_id])
    @investigation = investigation.decorate
  end

  def update_params
    return {} if params[:investigation].blank?

    params.require(:investigation).permit(editable_keys)
  end

  def editable_keys
    %i[description]
  end

  def set_last_case_view_cookie
    cookies[:last_case_view] = params[:action]
  end

  def count_to_display
    default_params ? Investigation.not_deleted.count : @pagy.count
  end

  def default_params
    [params[:case_owner], params[:case_type], params[:created_by], params[:priority], params[:teams_with_access], params[:hazard_type], params[:created_from_date], params[:created_to_date]].each do |param_value|
      return false unless param_value == "all" || param_value.blank?
    end

    params["case_status"] == "all" && params[:q].blank?
  end
end
