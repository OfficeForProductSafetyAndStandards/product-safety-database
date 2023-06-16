class Investigations::TestResults::FundingCertificateController < Investigations::BaseController
  before_action :set_investigation
  before_action :authorize_investigation_updates
  before_action :set_case_breadcrumbs

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

  def test_funding_certificate_params
    params.require(:set_test_result_certificate_on_case_form).permit(
      :tso_certificate_reference_number,
      tso_certificate_issue_date: %i[day month year]
    )
  end
end
