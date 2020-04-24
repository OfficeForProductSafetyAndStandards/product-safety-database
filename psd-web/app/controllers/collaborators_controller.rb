class CollaboratorsController < ApplicationController
  def new
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])

    authorize @investigation, :add_collaborators?

    @collaborator = @investigation.collaborators.new

    @teams = teams_without_access
  end

  def create
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])

    authorize @investigation, :add_collaborators?

    result = AddTeamToAnInvestigation.call(
      params.require(:collaborator).permit(:team_id, :include_message, :message).merge({
        investigation: @investigation,
        current_user: current_user
      })
    )

    if result.success?
      flash[:success] = I18n.t(
        :team_added_to_case,
        team_name: result.collaborator.team.name,
        scope: "case.add_team"
        )
      redirect_to investigation_path(@investigation)
    else
      @teams = teams_without_access
      @collaborator = result.collaborator
      render "collaborators/new"
    end
  end

private

  def teams_without_access
    Team.where.not(id: team_ids_with_access).order(:name)
  end

  def team_ids_with_access
    @investigation.collaborators.pluck(:team_id) + [@investigation.assignee_team.try(:id)]
  end
end
