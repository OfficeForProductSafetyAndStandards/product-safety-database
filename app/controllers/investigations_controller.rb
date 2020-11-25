class InvestigationsController < ApplicationController
  include InvestigationsHelper

  before_action :set_search_params, only: %i[index]
  before_action :set_investigation, only: %i[show status visibility created]
  before_action :build_breadcrumbs, only: %i[show]

  # GET /cases
  # GET /cases.json
  # GET /cases.xlsx
  def index
    respond_to do |format|
      format.html do
        @answer         = search_for_investigations(20)
        @investigations = InvestigationDecorator
                            .decorate_collection(@answer.records(includes: [{ owner_user: :organisation, owner_team: :organisation }, :products]))
      end
      format.xlsx do
        authorize Investigation, :export?

        @answer = search_for_investigations
        @investigations = @answer.records(includes: %i[complainant creator_user products owner_team owner_user])

        @activity_counts = Activity.group(:investigation_id).count
        @business_counts = InvestigationBusiness.unscoped.group(:investigation_id).count
        @product_counts = InvestigationProduct.unscoped.group(:investigation_id).count
        @corrective_action_counts = CorrectiveAction.group(:investigation_id).count
        @correspondence_counts = Correspondence.group(:investigation_id).count
        @test_counts = Test.group(:investigation_id).count
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

  # GET /cases/1/status
  # PATCH /cases/1/status
  def status
    authorize @investigation, :change_owner_or_status?
    @investigation.date_closed = update_params[:is_closed] == "true" ? Date.current : nil
    update!
  end

  # GET /cases/1/visibility
  # PATCH /cases/1/visibility
  def visibility
    authorize @investigation, :change_owner_or_status?
    update!
  end

  def created
    authorize @investigation, :view_non_protected_details?
  end

private

  def update!
    return if request.get?

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
    %i[description is_closed status_rationale is_private visibility_rationale]
  end

  def build_breadcrumbs
    @breadcrumbs = build_breadcrumb_structure
  end
end
