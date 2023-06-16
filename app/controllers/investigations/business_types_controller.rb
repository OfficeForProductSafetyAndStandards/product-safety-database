class Investigations::BusinessTypesController < Investigations::BaseController
  before_action :set_investigation
  before_action :authorize_investigation_non_protected_details
  before_action :set_case_breadcrumbs

  def new
    @business_type_form = SetBusinessTypeOnCaseForm.new
  end

  def create
    @business_type_form = SetBusinessTypeOnCaseForm.new(business_request_params)
    if @business_type_form.valid?
      session[:business_type] = @business_type_form.type
      redirect_to new_investigation_business_path(@investigation)
    else
      render :new
    end
  end

private

  def business_request_params
    params.require(:set_business_type_on_case_form).permit(:type)
  end
end
