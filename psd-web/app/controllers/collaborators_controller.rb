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

    @collaborator = @investigation.collaborators.new(collaborator_params)
    @collaborator.added_by_user = current_user

    begin
      if @collaborator.save
        NotifyTeamAddedToCaseJob.perform_later(@collaborator)
        redirect_to investigation_path(@investigation)
      else
        @teams = teams_without_access
        render "collaborators/new"
      end
    # If the team is already a collaborator, we can just redirect back to the case
    # page rather than displaying an error, as this should only have occured if the
    # user double-clicks the submit button or two users submit the same form at the
    # same time.
    rescue ActiveRecord::RecordNotUnique
      redirect_to investigation_path(@investigation)
    end
  end

private

  def teams_without_access
    Team.where.not(id: team_ids_with_access).order(:name)
  end

  def team_ids_with_access
    @investigation.collaborators.pluck(:team_id) + [@investigation.assignee_team.try(:id)]
  end

  def collaborator_params
    params.require(:collaborator).permit(:team_id, :message, :include_message)
  end
end
