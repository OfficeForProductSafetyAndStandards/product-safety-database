class Investigations::TestResults::FundingSourceController < ApplicationController
  before_action :set_investigation

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

  def set_investigation
    investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :update?
    @investigation = investigation.decorate
  rescue ActiveRecord::RecordNotFound
    render_404_page
  end

  def test_funding_request_params
    params.require(:set_test_result_funding_on_case_form).permit(:opss_funded)
  end
end
