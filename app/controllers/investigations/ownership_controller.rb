class Investigations::OwnershipController < ApplicationController
  include Wicked::Wizard
  before_action :set_investigation
  before_action :authorize_user

  steps :"select-owner", :confirm

  def show
    @potential_owner = form.owner&.decorate

    get_potential_assignees if step == :"select-owner"
    @investigation = @investigation.decorate
    render_wizard
  end

  def new
    session[session_store_key] = nil
    redirect_to wizard_path(steps.first, request.query_parameters)
  end

  def update
    unless form.valid?
      get_potential_assignees if step == :"select-owner"
      @investigation = @investigation.decorate
      return render_wizard
    end

    session[session_store_key] = form.attributes.compact
    redirect_to next_wizard_path
  end

  def create
    ChangeCaseOwner.call!(investigation: @investigation, owner: form.owner, rationale: form.owner_rationale, user: current_user)

    session[session_store_key] = nil

    message = "#{@investigation.case_type.upcase_first} owner changed to #{form.owner.decorate.display_name(viewer: current_user)}"
    @investigation = @investigation.decorate
    redirect_to investigation_path(@investigation), flash: { success: message }
  end

private

  def set_investigation
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
  end

  def authorize_user
    authorize @investigation, :change_owner_or_status?
  end

  def session_store_key
    "update_case_owner_#{@investigation.pretty_id}_params"
  end

  def form_params
    params[:change_case_owner_form] ||= {}
    params[:change_case_owner_form][:owner_id] = case params[:change_case_owner_form][:owner_id]
                                                 when "someone_in_your_team"
                                                   params[:change_case_owner_form][:select_team_member]
                                                 when "previous_owners"
                                                   params[:change_case_owner_form][:select_previous_owner]
                                                 when "other_team"
                                                   params[:change_case_owner_form][:select_other_team]
                                                 when "someone_else"
                                                   params[:change_case_owner_form][:select_someone_else]
                                                 else
                                                   params[:change_case_owner_form][:owner_id]
                                                 end
    params.require(:change_case_owner_form).permit(:owner_id, :owner_rationale).merge(session_params)
  end

  def session_params
    session[session_store_key] || {}
  end

  def form
    @form ||= ChangeCaseOwnerForm.new(form_params)
  end

  def get_potential_assignees
    @current_user_and_owner = [current_user, @investigation.owner, current_user.team].uniq
    @team_members = current_user.team.users.active.includes(:team)
    @other_teams = Team.not_deleted
    @other_users = User.active.includes(:team)
    @other_teams_added_to_case = Team.find(@investigation.collaboration_accesses.where("type IN (?)", ["Collaboration::Access::Edit", "Collaboration::Access::ReadOnly"]).map(&:collaborator_id))
    @default_opss_teams = (default_opss_teams - @current_user_and_owner - @other_teams_added_to_case)
  end

  def default_opss_teams
    if current_user.is_opss?
      Team.where("name IN (?)", ["OPSS Enforcement", "OPSS Incident Management", "OPSS Trading Standards Co-ordination", "OPSS Operational support unit"])
    else
      Team.where(name: "OPSS Incident Management")
    end
  end
end
