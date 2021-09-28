class BusinessRelationshipsController < ApplicationController
  before_action :set_investigation

  def edit
    investigation_business = InvestigationBusiness.find_by(id: params["id"])
    @business_relationship_form = BusinessRelationshipForm.new(id: investigation_business.id, relationship: investigation_business.relationship)
    @investigation_business = investigation_business.decorate
  end

  def update
    investigation_business = InvestigationBusiness.find_by(id: params["id"])
    @business_relationship_form = BusinessRelationshipForm.new(id: params["id"], relationship: params["business_relationship_form"]["relationship"], relationship_other: params["business_relationship_form"]["relationship_other"])
    byebug
    if @business_relationship_form.valid?
      byebug
      investigation_business.update!(relationship: @business_relationship_form.attributes["relationship"])
    end

    redirect_to investigation_businesses_path(@investigation), flash: { success: "Relationship was successfully updated" }
  end

private

  def set_investigation
    investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :view_non_protected_details?
    @investigation = investigation.decorate
  end
end
