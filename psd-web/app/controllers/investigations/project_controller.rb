class Investigations::ProjectController < ApplicationController
  include Wicked::Wizard

  steps :coronavirus, :project_details

  before_action :set_investigation, only: %i[show new create update]

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
    if @investigation.valid?(step)
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

  # Never trust parameters from the scary internet, only allow the white list through.
  def investigation_request_params
    # This must be done first because the browser will send no params if no radio is selected
    if step == :coronavirus
      params[:investigation] ||= { coronavirus_related: nil }
    end

    return {} if params[:investigation].blank?

    params.require(:investigation).permit(:user_title, :description, :coronavirus_related)
  end

  def set_investigation
    @investigation = Investigation::Project.new(investigation_params).decorate
  end
end
