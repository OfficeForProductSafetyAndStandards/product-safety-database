module Investigations
  class CorrespondenceRoutingController < ApplicationController
    def new
      authorize investigation, :update?
      correspondence_routing_form
    end

    def create
      authorize investigation, :update?
      return render "new" unless correspondence_routing_form.valid?

      case correspondence_routing_form.type
      when "email"
        redirect_to new_investigation_email_path(@investigation)
      when "meeting"
        redirect_to new_investigation_meeting_path(@investigation)
      when "phone_call"
        redirect_to new_investigation_phone_call_path(@investigation)
      end
    end

  private

    def investigation
      @investigation ||= Investigation.find_by!(pretty_id: params[:investigation_pretty_id]).decorate
    end

    def correspondence_routing_form
      @correspondence_routing_form ||= CorrespondenceRoutingForm.new(type: params[:type])
    end
  end
end
