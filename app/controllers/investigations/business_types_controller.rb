class Investigations::BusinessTypesController < Investigations::BaseController
  before_action :set_investigation
  before_action :authorize_investigation_non_protected_details
  before_action :set_investigation_breadcrumbs
  before_action :set_online_marketplaces

  def new
    @business_type_form = SetBusinessTypeOnCaseForm.new
  end

  def create
    @business_type_form = SetBusinessTypeOnCaseForm.new(business_request_params)
    if @business_type_form.valid?
      @business_type_form.set_params_on_session(session)
      redirect_to new_investigation_business_path(@investigation)
    else
      render :new
    end
  end

private

  def set_online_marketplaces
    @online_marketplaces = OnlineMarketplace.approved.order(:name)
  end

  def business_request_params
    params.require(:set_business_type_on_case_form).permit(:type)
  end
end
