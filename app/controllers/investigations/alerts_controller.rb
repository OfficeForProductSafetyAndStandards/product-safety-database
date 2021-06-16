class Investigations::AlertsController < ApplicationController
  include Pundit
  include ActionView::Helpers::NumberHelper

  before_action :set_investigation

  def about
  end

  def new
    @alert_form = AlertForm.new
  end

  def preview
    @alert_form = AlertForm.new(alert_request_params)
    get_preview
    set_user_count
    render :new unless @alert_form.valid?
  end

  def show
    render_wizard
  end

  def update
    if @alert.valid?
      return create if step == steps.last

      redirect_to next_wizard_path
    else
      render_wizard
    end
  end

  def create
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

      redirect_to investigation_path(@investigation), flash: { success: "Email alert sent to #{@user_count} users" }
    end
  end

private

  def clear_session
    session.delete(:alert)
  end

  def set_investigation
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize_investigation
  end

  def authorize_investigation
    authorize @investigation, :send_email_alert?
    @investigation = @investigation.decorate
  end

  def set_alert
    @alert = Alert.new alert_params.merge(
      investigation_id: @investigation.id,
      source: UserSource.new(user: current_user),
      investigation_url: investigation_url(@investigation)
    )
  end

  def store_alert
    session[:alert] = @alert.attributes
  end

  def alert_params
    alert_session_params.merge(alert_request_params).symbolize_keys
  end

  def alert_session_params
    session[:alert] || {}
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
