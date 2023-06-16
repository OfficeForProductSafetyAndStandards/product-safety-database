class Investigations::SummaryController < Investigations::BaseController
  before_action :set_investigation
  before_action :authorize_investigation_updates
  before_action :set_case_breadcrumbs

  def edit
    @form = ChangeCaseSummaryForm.new(summary: @investigation.description)
  end

  def update
    @form = ChangeCaseSummaryForm.new(params.require(:change_case_summary_form).permit(:summary))
    return render :edit, status: :unprocessable_entity unless @form.valid?

    ChangeCaseSummary.call!(investigation: @investigation_object, summary: @form.summary, user: current_user)
    redirect_to investigation_path(@investigation), flash: { success: "Case was successfully updated" }
  end
end
