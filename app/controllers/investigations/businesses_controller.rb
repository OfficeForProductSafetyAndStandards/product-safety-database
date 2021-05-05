class Investigations::BusinessesController < ApplicationController
  include CountriesHelper

  def index
    @investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id]).decorate
    authorize @investigation, :view_non_protected_details?

    @breadcrumbs = {
      items: [
        { text: "Cases", href: investigations_path(previous_search_params) },
        { text: @investigation.pretty_description }
      ]
    }
  end

  def new
    investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :update?
    @countries = all_countries
    @business = investigation.businesses.new(business_params)
    @investigation = investigation.decorate
  end

  def create
    investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :update?

    @business = investigation.businesses.new(business_params)

    if @business.invalid?
      @countries = all_countries
      @investigation = investigation.decorate
      return render :new
    end

    result = AddBusinessToCase.call(business: @business, investigation: investigation, user: current_user)

    return redirect_to investigation_businesses_path(investigation), flash: { success: "Business was successfully created." } if result.success?

    @countries = all_countries
    @investigation = investigation.decorate
    render :new
  end

  def show
    @investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id]).decorate
    authorize @investigation, :update?

    @business             = @investigation.businesses.find(params[:id])
    @remove_business_form = RemoveBusinessForm.new
  end

  def update
    authorize @investigation, :update?
    if business_valid?
      if step == :type
        assign_type
        redirect_to next_wizard_path
      else
        create!
      end
    else
      render_wizard
    end
  end

  def destroy
    investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :view_non_protected_details?

    @business             = investigation.businesses.find(params[:id])
    @remove_business_form = RemoveBusinessForm.new(remove_business_params)

    if @remove_business_form.invalid?
      @investigation = investigation.decorate
      return render :show
    end

    return redirect_to investigation_businesses_path(investigation, @business) unless @remove_business_form.remove?

    result = RemoveBusinessFromCase.call!(
      reason: @remove_business_form.reason,
      investigation: investigation,
      business: @business,
      user: current_user
    )

    if result.success?
      redirect_to investigation_businesses_path(investigation, @business), flash: { success: t(".business_successfully_deleted") }
    else
      @investigation = investigation.decorate
      render :show
    end
  end

  def type
    # It has been decided not to use another controller (i.e Investigation::InvestigationBusinessController new and create action)
    # So we need to check the HTTP verb to handle the rendering of the form and the posting of the action so that
    # upon form validation if errors need to be displayed the url remain the same: /case/:pretty_id/businesses/type
    if request.get?
      @investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id]).decorate
      # displays the InvestigationBusiness model form
      @add_business_to_case_form = AddBusinessToCaseForm.new
    else
      investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id])
      # builds the InvestigationBusiness model form
      @add_business_to_case = AddBusinessToCaseForm.new(investigation_business_params)

      if @add_business_to_case.invalid?
        @investigation = investigation.decorate
        return render :show
      end

      redirect_to new_investigation_business_path(investigation, business: { investigation_businesses_attributes: [@add_business_to_case.serializable_hash] })
    end
  end

private

  def investigation_business_params
    params.require(:investigation_business).permit(:relationship, :other_relationship)
  end

  def redirect_to_investigation_businesses_tab(flash)
    redirect_to investigation_businesses_path(@investigation), flash: flash
  end

  def set_investigation
    investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :view_non_protected_details?
    @investigation = investigation.decorate
  end

  def remove_business_params
    params.require(:remove_business_form).permit(:remove, :reason)
  end

  def business_params
    params.require(:business)
      .permit(
        :company_number,
        :legal_name,
        :trading_name,
        locations_attributes: %i[address_line_1 address_line_2 city county country name phone_number postal_code],
        contacts_attributes: %i[email job_title name phone_number],
        investigation_businesses_attributes: %i[relationship investigation_id]
      )
  end
end
