class Investigations::ActivitiesController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  before_action :set_investigation

  def new
    return unless params[:commit] == "Continue"

    case params[:activity_type]
    when "comment"
      redirect_to new_investigation_activity_comment_path(@investigation)
    when "email"
      redirect_to new_investigation_email_path(@investigation)
    when "phone_call"
      redirect_to new_investigation_phone_call_path(@investigation)
    when "meeting"
      redirect_to new_investigation_meeting_path(@investigation)
    when "product"
      redirect_to new_investigation_product_path(@investigation)
    when "testing_request"
      redirect_to new_request_investigation_tests_path(@investigation)
    when "testing_result"
      redirect_to new_result_investigation_tests_path(@investigation)
    when "corrective_action"
      redirect_to new_investigation_corrective_action_path(@investigation)
    when "business"
      redirect_to new_investigation_business_path(@investigation)
    when "visibility"
      redirect_to visibility_investigation_path(@investigation)
    when "alert"
      redirect_to new_investigation_alert_path(@investigation)
    else
      @activity_type_empty = true
    end
  end

private

  def set_investigation
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize @investigation, :show?
  end
end
