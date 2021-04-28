class Investigations::Businesses::TypeController < ApplicationController
  def show
    @investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id]).decorate
    @business_type_form = BusinessTypeForm.new
  end

  def create
    investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id])
    @business_type_form = BusinessTypeForm.new(business_params)

    if @business_type_form.invalid?
      @investigation = investigation.decorate
      return render :show
    end

    redirect_to investigation_businesses_details_path(investigation, business_type_form: @business_type_form.serializable_hash)
  end

private

  def business_params
    params.require(:business_type_form).permit(:relationship, :other_relationship)
  end
end
