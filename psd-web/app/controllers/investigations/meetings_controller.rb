class Investigations::MeetingsController < ApplicationController
  def show
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize @investigation, :view_protected_details?
    @meeting = @investigation.meetings.find(params[:id]).decorate
  end
end
