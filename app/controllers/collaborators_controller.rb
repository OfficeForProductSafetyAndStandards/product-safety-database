class CollaboratorsController < Investigations::BaseController
  # TODO: Move this into investigation controller directory
  before_action :set_investigation
  before_action :authorize_investigation_manage_collaborators, except: %i[index]
  before_action :set_case_breadcrumbs

  def index
    @collaborators = @investigation.collaboration_accesses.sorted_by_team_name
  end

  def new
    @form = AddTeamToCaseForm.new
    @teams = teams_without_access
  end

  def create
    @form = AddTeamToCaseForm.new(params.require(:add_team_to_case_form).permit(:team_id, :permission_level, :message, :include_message))

    unless @form.valid?
      @teams = teams_without_access
      return render(:new, status: :unprocessable_entity)
    end

    AddTeamToCase.call!(
      investigation: @investigation,
      collaboration_class: @form.collaboration_class,
      user: current_user,
      team: @form.team,
      message: @form.message
    )

    redirect_to investigation_collaborators_path(@investigation), flash: { success: "#{@form.team.name} added to the case" }
  end

  def edit
    @collaboration = @investigation.collaboration_accesses.changeable.find(params[:id])
    @collaborator = @collaboration.collaborator

    @edit_form = EditCaseCollaboratorForm.new(collaboration: @collaboration)
  end

  def update
    @collaboration = @investigation.collaboration_accesses.find_by(id: params[:id])

    return redirect_to investigation_collaborators_path(@investigation) unless @collaboration # Usually due to double form submission
    return render_404_page unless @collaboration.class.changeable?

    @collaborator = @collaboration.collaborator

    @edit_form = EditCaseCollaboratorForm.new(edit_params.merge(collaboration: @collaboration))

    return render :edit, status: :bad_request unless @edit_form.valid?

    if @edit_form.delete?
      RemoveTeamFromCase.call!(
        collaboration: @collaboration,
        user: current_user,
        message: @edit_form.message
      )

      flash[:success] = "#{@collaborator.display_name} has been removed from the case"
    else
      ChangeCasePermissionLevelForTeam.call!(
        existing_collaboration: @collaboration,
        user: current_user,
        new_collaboration_class: @edit_form.new_collaboration_class,
        message: @edit_form.message
      )

      flash[:success] = "#{@collaborator.display_name}'s case permission level has been changed"
    end

    redirect_to investigation_collaborators_path(@investigation)
  end

private

  def authorize_investigation_manage_collaborators
    authorize @investigation, :manage_collaborators?
  end

  def teams_without_access
    Team.not_deleted.where.not(id: team_ids_with_access).order(:name)
  end

  def team_ids_with_access
    @investigation.collaboration_accesses.where(collaborator_type: "Team").pluck(:collaborator_id)
  end

  def edit_params
    params.require(:edit_case_collaborator_form).permit(:permission_level, :include_message, :message)
  end
end
