class Investigations::TestResults::FundingSourceController < Investigations::BaseController
  before_action :set_investigation
  before_action :authorize_investigation_updates
  before_action :set_investigation_breadcrumbs

  def new
    @test_funding_form = SetTestResultFundingOnCaseForm.new
  end

  def create
    @test_funding_form = SetTestResultFundingOnCaseForm.new(test_funding_request_params)
    if @test_funding_form.valid?
      if @test_funding_form.is_opss_funded?
        redirect_to new_investigation_funding_certificate_path(@investigation)
      else
        redirect_to new_investigation_test_result_path(@investigation)
      end
    else
      render :new
    end
  end

private

  def test_funding_request_params
    params.require(:set_test_result_funding_on_case_form).permit(:opss_funded)
  end
end
