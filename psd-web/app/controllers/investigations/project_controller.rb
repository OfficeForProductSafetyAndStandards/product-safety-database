class Investigations::ProjectController < ApplicationController
  include Wicked::Wizard
  include FlowWithCoronavirusForm
  steps :coronavirus, :project_details

  before_action :set_investigation, only: %i[show new create update]
  before_action :validate_coronavirus_related_form,
                only: :update,
                if: -> { step == :coronavirus }

  # GET /xxx/step
  def show
    render_wizard
  end

  # GET /xxx/new
  def new
    session.delete model_key
    redirect_to wizard_path(steps.first)
  end

  # POST /xxx
  def create
    if @investigation.valid?
      CreateCase.call(investigation: @investigation, user: current_user)
      redirect_to investigation_path(@investigation), flash: { success: "Project was successfully created" }
    else
      render_wizard
    end
  end

  # PATCH/PUT /xxx
  def update
    return render_wizard unless @investigation.valid?(step)

    session[model_key] = @investigation.attributes

    if step == steps.last
      create
    else
      redirect_to next_wizard_path
    end
  end

private

  def investigation_session_params
    session[model_key] || {}
  end

  def investigation_params
    investigation_session_params.merge(investigation_request_params)
  end

  def investigation_request_params
    return {} if params[:investigation].blank?

    params.require(:investigation).permit(:user_title, :description, :coronavirus_related)
  end

  def set_investigation
    investigation = Investigation::Project.new(investigation_params).tap do |project|
      project.build_owner_user_collaboration(collaborator: current_user)
      project.build_owner_team_collaboration(collaborator: current_user.team)
    end
    @investigation = investigation.decorate
  end

  def coronavirus_form_params
    params.require(:investigation).permit(:coronavirus_related)
  end

  def validate_coronavirus_related_form
    return render_wizard unless assigns_coronavirus_related_from_form(@investigation, @coronavirus_related_form)
  end

  def model_key
    :project
  end
end
