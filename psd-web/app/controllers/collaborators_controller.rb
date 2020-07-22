class CollaboratorsController < ApplicationController
  before_action do
    find_investigation_from_params
  end

  def index
    @collaborators = @investigation.collaboration_accesses.sorted_by_team_name
  end

  def new
    authorize @investigation, :manage_collaborators?

    @form = AddTeamToCaseForm.new

    @teams = teams_without_access
  end

  def create
    authorize @investigation, :manage_collaborators?

    @form = AddTeamToCaseForm.new(params.require(:add_team_to_case_form).permit(:team_id, :message, :include_message))

    unless @form.valid?
      @teams = teams_without_access
      return render(:new, status: :unprocessable_entity)
    end

    AddTeamToCase.call!(
      @form.attributes.merge({
        investigation: @investigation,
        team: @form.team,
        user: current_user
      })
    )

    redirect_to investigation_collaborators_path(@investigation), flash: { success: "#{@form.team.name} added to the case" }
  end

  def edit
    authorize @investigation, :manage_collaborators?

    @collaboration = @investigation.collaborations.edit_and_read_only.find(params[:id])
    @collaborator = @collaboration.collaborator
    @edit_form = EditInvestigationCollaboratorForm.new(permission_level: EditInvestigationCollaboratorForm::PERMISSION_LEVEL_EDIT)
  end

  def update
    authorize @investigation, :manage_collaborators?

    @collaboration = @investigation.collaborations.edit_and_read_only.find(params[:id])
    @collaborator = @collaboration.collaborator
    @edit_form = EditInvestigationCollaboratorForm.new(edit_params
      .merge(investigation: @investigation, team: @collaborator, user: current_user))
    if @edit_form.save!
      flash[:success] = "#{@collaborator.name} has been removed from the case"
      redirect_to investigation_collaborators_path(@investigation)
    else
      render "edit"
    end
  end

private

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def find_investigation_from_params
    @investigation ||= Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  def teams_without_access
    Team.where.not(id: team_ids_with_access).order(:name)
  end

  def team_ids_with_access
    @investigation.collaboration_accesses.where(collaborator_type: "Team").pluck(:collaborator_id)
  end

  def edit_params
    params.require(:edit_investigation_collaborator_form).permit(:permission_level, :include_message, :message)
  end
end
