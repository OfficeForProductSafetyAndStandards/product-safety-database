class Investigations::BusinessesController < Investigations::BaseController
  include BusinessesHelper
  include CountriesHelper

  before_action :set_investigation
  before_action :set_investigation_business, except: %i[destroy remove]
  before_action :authorize_investigation_non_protected_details
  before_action :authorize_user_for_business_updates, except: %i[index new remove destroy]
  before_action :set_countries, only: %i[new create show update]
  before_action :set_investigation_breadcrumbs

  def index; end

  def new
    @business_form = AddBusinessToNotificationForm.new(current_user:)
    @business_form.locations = [Location.new]
    @business_form.contacts = [Contact.new]
  end

  def create
    @business_form = AddBusinessToNotificationForm.new(
      business_form_params.merge(
        current_user:,
        relationship: session[:business_type],
        online_marketplace_id: session[:online_marketplace_id],
        other_marketplace_name: session[:other_marketplace_name],
        authorised_representative_choice: session[:authorised_representative_choice],
      )
    )
    @business_form.primary_location.valid?
    if @business_form.valid?
      @business = @business_form.business_object

      if @business.save
        AddBusinessToNotification.call!(
          business: @business,
          relationship: @business_form.relationship,
          online_marketplace: @business_form.online_marketplace,
          other_marketplace_name: @business_form.other_marketplace_name,
          authorised_representative_choice: @business_form.authorised_representative_choice,
          notification: @investigation,
          user: current_user
        )
        redirect_to_investigation_businesses_tab success: "The business was created"
      else
        render :new
      end
    else
      render :new
    end
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
    @business = Business.find(params[:id])
    @remove_business_form = RemoveBusinessForm.new
  end

  def destroy
    @business = @investigation.businesses.find(params[:id])
    @remove_business_form = RemoveBusinessForm.new(remove_business_params)

    if @remove_business_form.invalid?
      return render :remove
    end

    return redirect_to investigation_businesses_path(@investigation, @business) unless @remove_business_form.remove?

    result = RemoveBusinessFromNotification.call!(
      reason: @remove_business_form.reason,
      notification: @investigation.object,
      business: @business,
      user: current_user
    )

    if result.success?
      redirect_to investigation_businesses_path(@investigation, @business), flash: { success: t(".business_successfully_deleted") }
    else
      render :remove
    end
  end

private

  def authorize_user_for_non_protected_details
    authorize @investigation, :view_non_protected_details?
  end

  def authorize_user_for_business_updates
    authorize @investigation, :update?
  end

  def set_investigation_business
    @investigation_business = InvestigationBusiness.new(business_id: params[:id], investigation_id: @investigation.id)
  end

  def business_form_params
    params.require(:add_business_to_notification_form).permit(
      :legal_name,
      :trading_name,
      :company_number,
      locations_attributes: %i[id name address_line_1 address_line_2 phone_number city county country postal_code],
      contacts_attributes: %i[id name email phone_number job_title]
    )
  end

  def redirect_to_investigation_businesses_tab(flash)
    redirect_to investigation_businesses_path(@investigation), flash:
  end

  def remove_business_params
    params.require(:remove_business_form).permit(:remove, :reason)
  end
end
