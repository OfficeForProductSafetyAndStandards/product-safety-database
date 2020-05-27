class Investigations::OwnershipController < ApplicationController
  include Wicked::Wizard
  before_action :set_investigation
  before_action :authorize_user
  before_action :potential_owner, only: %i[show create]
  before_action :store_owner, only: %i[update]

  steps :"select-owner", :confirm

  def show
    @potential_owner = potential_owner&.decorate
    render_wizard
  end

  def new
    clear_session
    redirect_to wizard_path(steps.first, request.query_parameters)
  end

  def update
    if owner_valid?
      redirect_to next_wizard_path
    else
      render_wizard
    end
  end

  def create
    @investigation.owner = potential_owner
    @investigation.owner_rationale = params[:investigation][:owner_rationale]
    @investigation.save
    redirect_to investigation_path(@investigation), flash: { success: "#{@investigation.case_type.upcase_first} owner changed to #{potential_owner.decorate.display_name}" }
  end

private

  def clear_session
    session[:owner_id] = nil
  end

  def set_investigation
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id]).decorate
  end

  def authorize_user
    authorize @investigation, :change_owner_or_status?
  end

  def owner_params
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
    params.require(:investigation).permit(:owner_id)
  end

  def store_owner
    session[:owner_id] = owner_params[:owner_id]
  end

  def owner_valid?
    if step == :"select-owner"
      if potential_owner.nil?
        @investigation.errors.add(:owner_id, :invalid, message: "Select case owner")
      end
    end
    @investigation.errors.empty?
  end

  def potential_owner
    User.find_by(id: session[:owner_id]) || Team.find_by(id: session[:owner_id])
  end
end
