class CollaboratorsController < ApplicationController
  before_action do
    find_investigation_from_params
  end

  def index
    @teams = @investigation.teams.order(:name)
  end

  def new
    authorize @investigation, :add_collaborators?

    @collaborator = @investigation.collaborators.new

    @teams = teams_without_access
  end

  def create
    authorize @investigation, :add_collaborators?

    result = AddTeamToAnInvestigation.call(
      params.require(:collaborator).permit(:team_id, :include_message, :message).merge({
        investigation: @investigation,
        current_user: current_user
      })
    )

    if result.success?
      redirect_to investigation_collaborators_path(@investigation)
    else
      @teams = teams_without_access
      @collaborator = result.collaborator
      render "collaborators/new"
    end
  end

  def edit
    authorize @investigation, :add_collaborators?

    @team = Team.find(params[:id])
    @collaborator = @investigation.collaborators.find_by! team_id: @team.id
    @edit_form = EditInvestigationCollaboratorForm.new
  end

  def update
    authorize @investigation, :add_collaborators?

    params.permit!
    @team = Team.find(params[:id])
    @edit_form = EditInvestigationCollaboratorForm.new(params[:edit_investigation_collaborator_form]
      .merge(investigation: @investigation, team: @team, user: current_user))
    if @edit_form.save
      flash[:success] = "#{@team.name} removed from the case"
      redirect_to investigation_collaborators_path(@investigation)
    else
      render "edit"
    end
  end

private

  def find_investigation_from_params
    @investigation ||= Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
  end

  def teams_without_access
    Team.where.not(id: team_ids_with_access).order(:name)
  end

  def team_ids_with_access
    @investigation.collaborators.pluck(:team_id) + [@investigation.assignee_team.try(:id)]
  end
end
