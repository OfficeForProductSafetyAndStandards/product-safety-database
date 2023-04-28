class Investigations::BusinessTypesController < ApplicationController
  before_action :set_investigation

  def new
    clear_session
    @business = Business.new
  end

  def create
    session[:business_type] = business_request_params[:type]
    redirect_to new_investigation_business_path(@investigation)
  end

private

  def set_investigation
    investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :view_non_protected_details?
    @investigation = investigation.decorate
  end

  def clear_session
    session.delete(:business_type)
  end

  def business_request_params
    params.require(:business).permit(:type)
  end
end
