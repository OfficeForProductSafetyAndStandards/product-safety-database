class Investigations::BusinessTypesController < Investigations::BaseController
  before_action :set_investigation
  before_action :authorize_investigation_non_protected_details
  before_action :set_investigation_breadcrumbs
  before_action :set_online_marketplaces

  def new
    @business_type_form = SetBusinessTypeOnCaseForm.new
    @business_type_form.clear_params_from_session(session)
  end

  def create
    @business_type_form = SetBusinessTypeOnCaseForm.new(business_request_params)
    if @business_type_form.valid?
      if @business_type_form.is_approved_online_marketplace?
        online_marketplace = @business_type_form.approved_online_marketplace
        online_marketplace.business = Business.create(trading_name: online_marketplace.name)
        online_marketplace.save!
        AddBusinessToNotification.call!(
          business: online_marketplace.business,
          relationship: "online_marketplace",
          online_marketplace:,
          notification: @investigation,
          user: current_user
        )

        redirect_to investigation_businesses_path(@investigation), success: "The business was created"
      else
        @business_type_form.set_params_on_session(session)
        redirect_to new_investigation_business_path(@investigation)
      end
    else
      render :new
    end
  end

private

  def set_online_marketplaces
    @online_marketplaces = OnlineMarketplace.approved.order(:name)
  end

  def business_request_params
    params.require(:set_business_type_on_case_form).permit(:type, :online_marketplace_id, :other_marketplace_name, :authorised_representative_choice)
  end
end
