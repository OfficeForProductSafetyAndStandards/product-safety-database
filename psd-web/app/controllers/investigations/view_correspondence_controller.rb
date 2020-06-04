class Investigations::ViewCorrespondenceController < ApplicationController
  def show
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize @investigation, :view_non_protected_details?
    @correspondence = @investigation.correspondences.find(params[:id])

    render "investigations/correspondence/show"
  end
end
