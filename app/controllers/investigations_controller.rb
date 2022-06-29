class InvestigationsController < ApplicationController
  include InvestigationsHelper

  before_action :set_search_params, only: %i[index]
  before_action :set_investigation, only: %i[show created]
  before_action :build_breadcrumbs, only: %i[show]

  # GET /cases
  # GET /cases.json
  # GET /cases.xlsx
  def index
    respond_to do |format|
      format.html do
        Rails.logger.error("Testing sentry config!")
        @answer         = search_for_investigations(20)
        @count          = count_to_display
        @investigations = InvestigationDecorator
                            .decorate_collection(@answer.records(includes: [{ owner_user: :organisation, owner_team: :organisation }, :products]))
        @page_name = "all_cases"
      end
    end
  end

  # GET /cases/1
  # GET /cases/1.json
  def show
    authorize @investigation, :view_non_protected_details?
    @complainant = @investigation.complainant&.decorate
    respond_to do |format|
      format.html
    end
  end

  # GET /cases/new
  def new
    return redirect_to new_ts_investigation_path unless current_user.is_opss?

    case params[:type]
    when "allegation"
      redirect_to new_allegation_path
    when "enquiry"
      redirect_to new_enquiry_path
    when "project"
      redirect_to new_project_path
    else
      @nothing_selected = true if params[:commit].present?
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

    render "investigations/index.html.erb"
  end

  def team_cases
    nil.first
    @page_name = "team_cases"
    @search = SearchParams.new({ "case_owner" => "my_team",
                                 "sort_by" => params["sort_by"],
                                 "sort_dir" => params["sort_dir"],
                                 "page_name" => @page_name })
    @answer         = search_for_investigations(20)
    @investigations = InvestigationDecorator
                        .decorate_collection(@answer.records(includes: [{ owner_user: :organisation, owner_team: :organisation }, :products]))

    render "investigations/index.html.erb"
  end

private

  def update!
    return unless request.patch?

    respond_to do |format|
      if @investigation.update(update_params)
        format.html do
          redirect_to investigation_path(@investigation),
                      flash: {
                        success: "#{@investigation.case_type.upcase_first} was successfully updated"
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
    default_params ? Investigation.count : @answer.total_count
  end

  def default_params
    [params[:case_owner], params[:case_type], params[:created_by], params[:priority], params[:teams_with_access]].each do |param_value|
      return false unless ["all", nil].include? param_value
    end

    params["case_status"] == "all" && params[:q].blank?
  end
end
