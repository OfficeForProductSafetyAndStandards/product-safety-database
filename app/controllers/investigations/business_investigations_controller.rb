class Investigations::BusinessInvestigationsController < ApplicationController
  def show
    @investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id]).decorate
    @business_investigation_form = BusinessInvestigationForm.new
  end

  def create
    investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id])
    @business_investigation_form = BusinessInvestigationForm.new(business_params)

    if @business_investigation_form.invalid?
      @investigation = investigation.decorate
      return render :show
    end

    redirect_to new_investigation_business_path(investigation, business: { investigation_businesses_attributes: [@business_investigation_form.serializable_hash] })
  end

private

  def business_params
    params.require(:business_investigation_form).permit(:relationship, :other_relationship)
  end
end
