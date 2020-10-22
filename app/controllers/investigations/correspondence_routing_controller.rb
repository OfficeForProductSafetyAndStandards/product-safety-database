module Investigations
  class CorrespondenceRoutingController < ApplicationController
    def new
      authorize investigation, :update?
      correspondence_type_form
    end

    def create
      authorize investigation, :update?
      return render "new" unless correspondence_type_form.valid?

      case correspondence_type_form.type
      when "email"
        redirect_to new_investigation_email_path(@investigation)
      when "phone_call"
        redirect_to new_investigation_phone_call_path(@investigation)
      end
    end

  private

    def investigation
      @investigation ||= Investigation.find_by!(pretty_id: params[:investigation_pretty_id]).decorate
    end

    def correspondence_type_form
      @correspondence_type_form ||= CorrespondenceTypeForm.new(type: params[:type])
    end
  end
end
