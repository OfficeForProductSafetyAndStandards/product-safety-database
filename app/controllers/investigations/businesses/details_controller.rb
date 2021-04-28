class Investigations::Businesses::DetailsController < ApplicationController
  include CountriesHelper

  def show
    @countries = all_countries
    @investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id]).decorate
    @business_form = BusinessForm.new(business_type_params)
  end

  def create
    investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :update?
    @business_form = BusinessForm.new(business_form_params)

    return render :show if @business_form.invalid?

    AddBusinessToCase.call!(
      business_form
        .serializable_hash(methods: %i[primary_location primary_contact])
        .merge(user: current_user, investigation: investigation)
    )
  end

private

  def business_type_params
    params.require(:business_type_form).permit(:relationship, :other_relationship)
  end

  def business_form_params
    params.require(:business_form).permit(
      :relationship,
      :other_relationship,
      :trading_name,
      :legal_name,
      :company_number,
      primary_location: %i[name address_line_1 address_line_2 city county postal_code country],
      primary_contact: %i[name email phone_number job_title]
    )
  end
end
