class BusinessRelationshipsController < ApplicationController
  before_action :set_investigation

  def new
    @business = Business.find_by(id: params[:business_id])
    @investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id]).decorate
    @business_relationship_form = BusinessRelationshipForm.new
  end

  def create
    @business_relationship_form = BusinessRelationshipForm.new(business_relationship_params)
    @business = Business.find_by(id: params[:business_id])

    return render(:new) if @business_relationship_form.invalid?

    CreateBusinessRelationship.call!(@business_relationship_form.attributes.merge(
      {
        user: current_user,
        investigation: @investigation,
        business: @business
      }
    ))

    redirect_to investigation_businesses_path(@investigation), flash: { success: "Business relationship was successfully created" }
  end

  def edit
    investigation_business = InvestigationBusiness.find_by(id: params["id"])
    @business_relationship_form = BusinessRelationshipForm.from(investigation_business)
    @investigation_business = investigation_business.decorate
  end

  def update
    @investigation_business = InvestigationBusiness.find_by(id: params["id"])
    @business_relationship_form = BusinessRelationshipForm.new(business_relationship_params)

    return render(:edit) if @business_relationship_form.invalid?

    UpdateBusinessRelationship.call!(@business_relationship_form.attributes.merge(
      {
        user: current_user,
        investigation: @investigation,
        investigation_business: @investigation_business
      }
    ))

    redirect_to investigation_businesses_path(@investigation), flash: { success: "Business type was successfully updated" }
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
