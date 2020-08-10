class Investigations::OwnershipController < ApplicationController
  include Wicked::Wizard
  before_action :set_investigation
  before_action :authorize_user

  steps :"select-owner", :confirm

  def show
    @potential_owner = form.owner&.decorate
    render_wizard
  end

  def new
    session[session_store_key] = nil
    redirect_to wizard_path(steps.first, request.query_parameters)
  end

  def update
    return render_wizard unless form.valid?

    session[session_store_key] = form.attributes.compact
    redirect_to next_wizard_path
  end

  def create
    ChangeCaseOwner.call!(investigation: @investigation, owner: form.owner, rationale: form.owner_rationale, user: current_user)

    session[session_store_key] = nil

    message = "#{@investigation.case_type.upcase_first} owner changed to #{form.owner.decorate.display_name(viewer: current_user)}"
    redirect_to investigation_path(@investigation), flash: { success: message }
  end

private

  def set_investigation
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id]).decorate
  end

  def authorize_user
    authorize @investigation, :change_owner_or_status?
  end

  def session_store_key
    "update_case_owner_#{@investigation.pretty_id}_params"
  end

  def form_params
    params[:investigation] ||= {}
    params[:investigation][:owner_id] = case params[:investigation][:owner_id]
                                        when "someone_in_your_team"
                                          params[:investigation][:select_team_member]
                                        when "previous_owners"
                                          params[:investigation][:select_previous_owner]
                                        when "other_team"
                                          params[:investigation][:select_other_team]
                                        when "someone_else"
                                          params[:investigation][:select_someone_else]
                                        else
                                          params[:investigation][:owner_id]
                                        end
    params.require(:investigation).permit(:owner_id, :owner_rationale).merge(session_params)
  end

  def session_params
    session[session_store_key] || {}
  end

  def form
    @form ||= ChangeCaseOwnerForm.new(form_params)
  end
end
