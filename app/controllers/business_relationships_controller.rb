class BusinessRelationshipsController < ApplicationController
  before_action :set_investigation

  def edit
    investigation_business = InvestigationBusiness.find_by(id: params["id"])
    @business_relationship_form = BusinessRelationshipForm.from(investigation_business)
    @investigation_business = investigation_business.decorate
  end

  def update
    investigation_business = InvestigationBusiness.find_by(id: params["id"])
    @business_relationship_form = BusinessRelationshipForm.new(business_relationship_params)

    if @business_relationship_form.valid?
      UpdateBusinessRelationship.call!(@business_relationship_form.attributes.merge(
        {
          user: current_user,
          investigation: @investigation,
          investigation_business: investigation_business
        }
      ))
    end

    redirect_to investigation_businesses_path(@investigation), flash: { success: "Relationship was successfully updated" }
  end

private

  def set_investigation
    investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :view_non_protected_details?
    @investigation = investigation.decorate
  end

  def business_relationship_params
    params.require(:business_relationship_form).permit(:relationship, :relationship_other)
  end
end
