class Investigations::BusinessesController < ApplicationController
  include BusinessesHelper
  include CountriesHelper

  before_action :set_investigation
  before_action :set_investigation_business, except: %i[destroy remove]
  before_action :authorize_user_for_business_updates, except: %i[index new remove destroy]
  before_action :set_countries, only: %i[new create show update]
  before_action :set_business_location_and_contact, only: %i[new create show update]

  def index
    @breadcrumbs = {
      items: [
        { text: "Cases", href: all_cases_investigations_path },
        { text: @investigation.pretty_description }
      ]
    }
  end

  def new
  end

  def create
    # @business = Business.new(business_params)
    AddBusinessToCase.call!(
      business: @business,
      relationship: session[:type],
      investigation: @investigation,
      user: current_user
    )
    redirect_to_investigation_businesses_tab success: "The business was created"
  end

  def show
    @business = Business.find(params[:id])
  end

  def update
    @business = Business.find(params[:id])
    if @business.update(business_params)
      redirect_to investigations_business_path(@investigation, @business)
    else
      render :show
    end
  end

  def remove
    @investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id]).decorate
    authorize @investigation, :view_non_protected_details?
    @business = Business.find(params[:id])
    @remove_business_form = RemoveBusinessForm.new
  end

  def destroy
  #   investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id])
  #   authorize investigation, :view_non_protected_details?

  #   @business             = investigation.businesses.find(params[:id])
  #   @remove_business_form = RemoveBusinessForm.new(remove_business_params)

  #   if @remove_business_form.invalid?
  #     @investigation = investigation.decorate
  #     return render :remove
  #   end

  #   return redirect_to investigation_businesses_path(investigation, @business) unless @remove_business_form.remove?

  #   result = RemoveBusinessFromCase.call!(
  #     reason: @remove_business_form.reason,
  #     investigation:,
  #     business: @business,
  #     user: current_user
  #   )

  #   if result.success?
  #     redirect_to investigation_businesses_path(investigation, @business), flash: { success: t(".business_successfully_deleted") }
  #   else
  #     @investigation = investigation.decorate
  #     render :remove
  #   end
  end

private

  def set_investigation
    investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :view_non_protected_details?
    @investigation = investigation.decorate
  end

  def authorize_user_for_business_updates
    authorize @investigation, :update?
  end

#   def create!
#     if @business.valid?
#     else
#       render_wizard
#     end
#   end

  def set_investigation_business
    @investigation_business = InvestigationBusiness.new(business_id: params[:id], investigation_id: @investigation.id)
  end

  def set_business_location_and_contact
    @business = Business.new
    @business.locations.build unless @business.primary_location
    @business.contacts.build unless @business.primary_contact
    defaults_on_primary_location @business
  end

  # def redirect_to_investigation_businesses_tab(flash)
  #   redirect_to investigation_businesses_path(@investigation), flash:
  # end

  def remove_business_params
    params.require(:remove_business_form).permit(:remove, :reason)
  end
end
