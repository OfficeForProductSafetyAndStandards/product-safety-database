class Investigations::TestResults::FundingCertificateController < ApplicationController
  before_action :set_investigation

  def new
    @test_certificate_form = SetTestResultCertificateOnCaseForm.new
    session[:test_result_certificate] = nil
  end

  def create
    @test_certificate_form = SetTestResultCertificateOnCaseForm.new(test_funding_certificate_params)
    if @test_certificate_form.valid?
      session[:test_result_certificate] = test_funding_certificate_params.to_h
      redirect_to new_investigation_test_result_path(@investigation)
    else
      render :new
    end
  end

private

  def set_investigation
    investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :update?
    @investigation = investigation.decorate
  end

  def test_funding_certificate_params
    params.require(:set_test_result_certificate_on_case_form).permit(
      :tso_certificate_reference_number,
      tso_certificate_issue_date: %i[day month year]
    )
  end
end
