class Investigations::SummaryController < Investigations::BaseController
  before_action :set_investigation
  before_action :authorize_investigation_updates
  before_action :set_investigation_breadcrumbs

  def edit
    @form = ChangeNotificationSummaryForm.new(summary: @investigation.description)
  end

  def update
    @form = ChangeNotificationSummaryForm.new(params.require(:change_notification_summary_form).permit(:summary))
    return render :edit, status: :unprocessable_entity unless @form.valid?

    ChangeNotificationSummary.call!(notification: @investigation_object, summary: @form.summary, user: current_user)
    redirect_to investigation_path(@investigation), flash: { success: "Notification was successfully updated" }
  end
end
