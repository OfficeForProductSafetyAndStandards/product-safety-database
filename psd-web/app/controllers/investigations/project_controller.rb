class Investigations::ProjectController < ApplicationController
  include Wicked::Wizard
  include CoronavirusForm
  steps :coronavirus, :project_details

  before_action :set_investigation, only: %i[show new create update]
  before_action :set_coronavirus_info_from_form, only: :update, if: -> { step == :coronavirus }

  #GET /xxx/step
  def show
    render_wizard
  end

  # GET /xxx/new
  def new
    session.delete :investigation
    redirect_to wizard_path(steps.first)
  end

  # POST /xxx
  def create
    if @investigation.valid?
      @investigation.save
      redirect_to investigation_path(@investigation), flash: { success: "Project was successfully created" }
    else
      render_wizard
    end
  end

  # PATCH/PUT /xxx
  def update
    return render_wizard unless @investigation.valid?(step)

    session[:investigation] = @investigation.attributes

    if step == steps.last
      create
    else
      redirect_to next_wizard_path
    end
  end

private

  def investigation_session_params
    session[:investigation] || {}
  end

  def investigation_params
    investigation_session_params.merge(investigation_request_params)
  end

  def investigation_request_params
    return {} if params[:investigation].blank?

    params.require(:investigation).permit(:user_title, :description, :coronavirus_related)
  end

  def set_investigation
    @investigation = Investigation::Project.new(investigation_params).decorate
  end

  def coronvirus_form_params
    params.require(:investigation).permit(:coronavirus_related)
  end

  def set_coronavirus_info_from_form
    assigns_coronavirus_related_from_form(@investigation, coronvirus_form_params)
  end
end
