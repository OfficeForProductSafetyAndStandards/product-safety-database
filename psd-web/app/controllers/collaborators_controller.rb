class CollaboratorsController < ApplicationController
  def new
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])

    @collaborator = @investigation.collaborators.new

    @teams = teams_without_access
  end

  def create
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])

    @collaborator = @investigation.collaborators.new(collaborator_params)
    @collaborator.added_by_user = current_user

    if @collaborator.save
      redirect_to investigation_path(@investigation)
    else
      @teams = teams_without_access
      render "collaborators/new"
    end
  end

private

  def teams_without_access
    Team.where.not(id: team_ids_with_access).order(:name)
  end

  def team_ids_with_access
    @investigation.collaborators.pluck(:team_id) + [@investigation.assignee_team.id]
  end

  def collaborator_params
    params.require(:collaborator).permit(:team_id, :message, :include_message)
  end
end
