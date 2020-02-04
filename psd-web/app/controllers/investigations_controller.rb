class InvestigationsController < ApplicationController
  include InvestigationsHelper

  before_action :set_search_params, only: %i[index]
  before_action :set_investigation, only: %i[show status visibility edit_summary created]
  before_action :build_breadcrumbs, only: %i[show]

  # GET /cases
  # GET /cases.json
  # GET /cases.xlsx
  def index
    respond_to do |format|
      format.html do
        @answer         = search_for_investigations(20)
        @investigations = InvestigationDecorator
                            .decorate_collection(@answer.records(includes: [{ assignable: :organisation }, :products]))
      end
      format.xlsx do
        @answer = search_for_investigations
        @investigations = Investigation.eager_load(:complainant,
                                                   :source).where(id: @answer.results.map(&:_id))

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
    update
  end

  # GET /cases/1/visibility
  # PATCH /cases/1/visibility
  def visibility
    update
  end

  # GET /cases/1/edit_summary
  # PATCH /cases/1/edit_summary
  def edit_summary
    update
  end

  def created; end

private

  def update
    respond_to do |format|
      if @investigation.update(update_params)
        format.html {
          redirect_to investigation_path(@investigation), flash: {
            success: "#{@investigation.case_type.titleize} was successfully updated."
          }
        }
        format.json { render :show, status: :ok, location: @investigation }
      else
        format.html { render action_name }
        format.json { render json: @investigation.errors, status: :unprocessable_entity }
      end
    end
  end

  def set_investigation
    investigation = Investigation.find_by!(pretty_id: params[:pretty_id])
    authorize investigation
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

  def set_suggested_previous_assignees
    @suggested_previous_assignees = suggested_previous_assignees
  end
end
