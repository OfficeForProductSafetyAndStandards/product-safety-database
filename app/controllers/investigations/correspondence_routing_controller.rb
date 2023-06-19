module Investigations
  class CorrespondenceRoutingController < Investigations::BaseController
    before_action :set_investigation
    before_action :authorize_investigation_updates
    before_action :set_investigation_breadcrumbs

    def new
      correspondence_type_form
    end

    def create
      return render "new" unless correspondence_type_form.valid?

      case correspondence_type_form.type
      when "email"
        redirect_to new_investigation_email_path(@investigation)
      when "phone_call"
        redirect_to new_investigation_phone_call_path(@investigation)
      end
    end

  private

    def correspondence_type_form
      @correspondence_type_form ||= CorrespondenceTypeForm.new(type: params[:type])
    end
  end
end
