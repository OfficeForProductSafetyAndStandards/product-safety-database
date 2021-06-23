class Investigations::AlertsController < ApplicationController
  include Pundit
  include ActionView::Helpers::NumberHelper

  before_action :set_investigation

  def about
    set_investigation
    @investigation = @investigation.decorate
  end

  def new
    set_investigation
    authorize @investigation, :investigation_restricted?

    @alert_form = AlertForm.new(alert_request_params.merge(investigation_url: investigation_url(@investigation)))
    @investigation = @investigation.decorate
  end

  def preview
    set_investigation
    authorize @investigation, :investigation_restricted?

    @alert_form = AlertForm.new(alert_request_params.merge(investigation_url: investigation_url(@investigation)))
    @investigation = @investigation.decorate
    
    return render :new unless @alert_form.valid?

    @user_count = number_with_delimiter(User.active.count, delimiter: ",")
    get_preview
  end

  def create
    set_investigation
    authorize @investigation, :investigation_restricted?

    @alert_form = AlertForm.new(alert_request_params)
    set_user_count
    if @alert_form.valid?
      AddAlert.call!(
        @alert_form.attributes.merge({
          investigation: @investigation,
          user: current_user,
          user_count: @user_count
        })
      )

      @investigation = @investigation.decorate
      redirect_to investigation_path(@investigation), flash: { success: "Email alert sent to #{@user_count} users" }
    end
  end

private

  def set_investigation
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize_investigation
  end

  def authorize_investigation
    authorize @investigation, :send_email_alert?
  end

  def set_alert
    @alert = Alert.new alert_params.merge(
      investigation_id: @investigation.id,
      source: UserSource.new(user: current_user),
      investigation_url: investigation_url(@investigation)
    )
  end

  def alert_request_params
    return {} unless params.key? :alert_form

    params.require(:alert_form).permit(:summary, :description)
  end

  def set_user_count
    @user_count = number_with_delimiter(User.active.count, delimiter: ",")
  end

  def get_preview
    @preview = NotificationsClient.instance.generate_template_preview(
      NotifyMailer::TEMPLATES[:alert],
      personalisation: {
        email_text: @alert_form.description,
        subject_text: @alert_form.summary
      }
    )
  end
end
