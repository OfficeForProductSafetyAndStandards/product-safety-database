class CollaboratorsController < ApplicationController
  def index
    @investigation = find_investigation_from_params
    @teams = @investigation.teams.order(:name)
  end

  def new
    @investigation = find_investigation_from_params

    authorize @investigation, :add_collaborators?

    @collaborator = @investigation.collaborators.new

    @teams = teams_without_access
  end

  def create
    @investigation = find_investigation_from_params

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

private

  def find_investigation_from_params
    Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
  end

  def teams_without_access
    Team.where.not(id: team_ids_with_access).order(:name)
  end

  def team_ids_with_access
    @investigation.collaborators.pluck(:team_id) + [@investigation.owner_team.try(:id)]
  end
end
