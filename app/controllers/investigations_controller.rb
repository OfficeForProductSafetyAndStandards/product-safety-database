class InvestigationsController < ApplicationController
  include InvestigationsHelper

  before_action :set_search_params, only: %i[index]
  before_action :set_investigation, only: %i[show created cannot_close confirm_deletion destroy]
  before_action :build_breadcrumbs, only: %i[show]

  # GET /cases
  def index
    respond_to do |format|
      format.html do
        @answer         = search_for_investigations(20)
        @count          = count_to_display
        @investigations = InvestigationDecorator
                            .decorate_collection(@answer.records(includes: [{ owner_user: :organisation, owner_team: :organisation }, :products]))
        @page_name = "all_cases"
      end
    end
  end

  # GET /cases/1
  def show
    authorize @investigation, :view_non_protected_details?
    @complainant = @investigation.complainant&.decorate
    respond_to do |format|
      format.html
    end
  end

  def created
    authorize @investigation, :view_non_protected_details?
  end

  def your_cases
    @page_name = "your_cases"
    @search = SearchParams.new({ "case_owner" => "me",
                                 "sort_by" => params["sort_by"],
                                 "sort_dir" => params["sort_dir"],
                                 "page_name" => "team_cases" })
    @answer         = search_for_investigations(20)
    @investigations = InvestigationDecorator
                        .decorate_collection(@answer.records(includes: [{ owner_user: :organisation, owner_team: :organisation }, :products]))

    render "investigations/index"
  end

  def assigned_cases
    @page_name = "assigned_cases"

    @search = SearchParams.new(
      {
        "case_owner" => "all",
        "teams_with_access" => "my_team",
        "created_by" => "others",
        "sort_by" => params["sort_by"],
        "sort_dir" => params["sort_dir"],
        "page_name" => "team_cases"
      }
    )
    @answer         = search_for_investigations(20)
    @investigations = InvestigationDecorator
                        .decorate_collection(@answer.records(includes: [{ owner_user: :organisation, owner_team: :organisation }, :products]))

    render "investigations/index"
  end

  def team_cases
    @page_name = "team_cases"
    @search = SearchParams.new({ "case_owner" => "my_team",
                                 "sort_by" => params["sort_by"],
                                 "sort_dir" => params["sort_dir"],
                                 "page_name" => @page_name })
    @answer         = search_for_investigations(20)
    @investigations = InvestigationDecorator
                        .decorate_collection(@answer.records(includes: [{ owner_user: :organisation, owner_team: :organisation }, :products]))

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

    @delete_investigation_form = DeleteInvestigationForm.new(investigation: @investigation)

    if @delete_investigation_form.valid?
      DeleteInvestigation.call!(investigation: @investigation, deleted_by: current_user)
      redirect_to your_cases_investigations_path, flash: { success: "The case was deleted" }
    else
      redirect_to your_cases_investigations_path, flash: { warning: "The case could not be deleted" }
    end
  end

private

  def update!
    return unless request.patch?

    respond_to do |format|
      if @investigation.update(update_params)
        format.html do
          redirect_to investigation_path(@investigation),
                      flash: {
                        success: "Case was successfully updated"
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

  def build_breadcrumbs
    @breadcrumbs = build_breadcrumb_structure
  end

  def count_to_display
    default_params ? Investigation.not_deleted.count : @answer.total_count
  end

  def default_params
    [params[:case_owner], params[:case_type], params[:created_by], params[:priority], params[:teams_with_access], params[:hazard_type]].each do |param_value|
      return false unless param_value == "all" || param_value.blank?
    end

    params["case_status"] == "all" && params[:q].blank?
  end
end
