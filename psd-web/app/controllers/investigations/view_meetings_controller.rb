class Investigations::ViewMeetingsController < ApplicationController
  def show
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize @investigation, :view_non_protected_details?
    @meeting = @investigation.meetings.find(params[:id])

    render "investigations/meetings/show"
  end
end
