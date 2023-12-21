class Investigations::OwnershipController < Investigations::BaseController
  include Wicked::Wizard

  before_action :set_investigation
  before_action :authorize_investigation_change_owner_or_status
  before_action :set_investigation_breadcrumbs

  steps :"select-owner", :confirm

  def show
    return redirect_to wizard_path(:"select-owner") if form_params[:owner_id].blank? && (step != :"select-owner")

    @potential_owner = form.owner&.decorate
    get_potential_assignees if step == :"select-owner"
    render_wizard
  end

  def new
    session[session_store_key] = nil
    redirect_to wizard_path(steps.first, request.query_parameters)
  end

  def update
    unless form.valid?
      get_potential_assignees if step == :"select-owner"
      return render_wizard
    end

    session[session_store_key] = form.attributes.compact
    redirect_to next_wizard_path
  end

  def create
    ChangeNotificationOwner.call!(notification: @investigation, owner: form.owner, rationale: form.owner_rationale, user: current_user)

    session[session_store_key] = nil

    message = "Notification owner changed to #{form.owner.decorate.display_name(viewer: current_user)}"
    @investigation = @investigation.decorate
    redirect_to investigation_path(@investigation), flash: { success: message }
  end

private

  def session_store_key
    "update_case_owner_#{@investigation.pretty_id}_params"
  end

  def form_params
    params[:change_notification_owner_form] ||= {}
    params[:change_notification_owner_form][:owner_id] = case params[:change_notification_owner_form][:owner_id]
                                                 when "someone_else_in_your_team"
                                                   params[:change_notification_owner_form][:select_team_member]
                                                 when "previous_owners"
                                                   params[:change_notification_owner_form][:select_previous_owner]
                                                 when "other_team"
                                                   params[:change_notification_owner_form][:select_other_team]
                                                 when "someone_else"
                                                   params[:change_notification_owner_form][:select_someone_else]
                                                 else
                                                   params[:change_notification_owner_form][:owner_id]
                                                 end
    params.require(:change_notification_owner_form).permit(:owner_id, :owner_rationale).merge(session_params)
  end

  def session_params
    session[session_store_key] || {}
  end

  def form
    @form ||= ChangeNotificationOwnerForm.new(form_params)
  end

  def get_potential_assignees
    @team_members = current_user.team.users.active.includes(:team) - [@investigation.owner_user, current_user]
    @other_teams = Team.not_deleted
    @other_users = User.active.includes(:team)
    @other_teams_added_to_case = @investigation.non_owner_teams_with_access
    @default_opss_teams = (Team.get_visible_teams(current_user) - [@investigation.owner, current_user.team] - @other_teams_added_to_case)
  end
end
