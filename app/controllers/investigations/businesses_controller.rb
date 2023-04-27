class Investigations::BusinessesController < ApplicationController
  include BusinessesHelper
  include CountriesHelper
  include Wicked::Wizard
  skip_before_action :setup_wizard, only: %i[remove destroy]
  steps :type, :details

  before_action :set_investigation, only: %i[index update new show]
  before_action :set_countries, only: %i[update show]
  before_action :set_business_location_and_contact, only: %i[update new show]
  before_action :store_business, only: %i[update]
  before_action :set_investigation_business, except: %i[destroy remove]
  before_action :business_request_params, only: %i[new]

  def index
    @breadcrumbs = {
      items: [
        { text: "Cases", href: all_cases_investigations_path },
        { text: @investigation.pretty_description }
      ]
    }
  end

  def new
    clear_session
    redirect_to wizard_path(steps.first)
  end

  def create
    authorize @investigation, :update?
    create!
  end

  # This action is used for the edit flow
  def show
    authorize @investigation, :update?
    render_wizard
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

  def remove
    @investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id]).decorate
    authorize @investigation, :view_non_protected_details?
    @business = Business.find(params[:id])
    @remove_business_form = RemoveBusinessForm.new
  end

  def destroy
    investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :view_non_protected_details?

    @business             = investigation.businesses.find(params[:id])
    @remove_business_form = RemoveBusinessForm.new(remove_business_params)

    if @remove_business_form.invalid?
      @investigation = investigation.decorate
      return render :remove
    end

    return redirect_to investigation_businesses_path(investigation, @business) unless @remove_business_form.remove?

    result = RemoveBusinessFromCase.call!(
      reason: @remove_business_form.reason,
      investigation:,
      business: @business,
      user: current_user
    )

    if result.success?
      redirect_to investigation_businesses_path(investigation, @business), flash: { success: t(".business_successfully_deleted") }
    else
      @investigation = investigation.decorate
      render :remove
    end
  end

private

  def create!
    if @business.valid?
      AddBusinessToCase.call!(
        business: @business,
        relationship: session[:type],
        investigation: @investigation,
        user: current_user
      )
      redirect_to_investigation_businesses_tab success: "The business was created"
    else
      render_wizard
    end
  end

  def set_investigation_business
    @investigation_business = InvestigationBusiness.new(business_id: params[:id], investigation_id: @investigation.id)
  end

  def assign_type
    session[:type] = business_type_params[:type] == "other" ? business_type_params[:type_other] : business_type_params[:type]
  end

  def clear_session
    session.delete(:business)
    session.delete(:contact)
    session.delete(:location)
  end

  def business_valid?
    if step == :type
      if business_type_params[:type].blank?
        @business.errors.add(:type, "Please select a business type")
      end
    else
      @business.valid?
    end
    @business.errors.empty?
  end

  def business_request_params
    return {} if params[:business].blank?

    business_params
  end

  def business_step_params
    business_session_params.merge(business_request_params)
  end

  def business_session_params
    session[:business] || {}
  end

  def set_business_location_and_contact
    @business = Business.new(business_step_params)
    @business.locations.build unless @business.primary_location
    @business.contacts.build unless @business.primary_contact
    defaults_on_primary_location @business
  end

  def store_business
    session[:business] = @business.attributes
    session[:contact] = @business.contacts.first.attributes
    session[:location] = @business.locations.first.attributes
  end

  def business_type_params
    params.require(:business).permit(:type, :type_other)
  end

  def redirect_to_investigation_businesses_tab(flash)
    redirect_to investigation_businesses_path(@investigation), flash:
  end

  def set_investigation
    investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :view_non_protected_details?
    @investigation = investigation.decorate
  end

  def remove_business_params
    params.require(:remove_business_form).permit(:remove, :reason)
  end
end
