module Investigations
  class AccidentOrIncidentsTypeController < ApplicationController
    def new
      authorize investigation, :update?
      accident_or_incident_type_form
    end

    def create
      authorize investigation, :update?
      return render(:new) if accident_or_incident_type_form.invalid?
      redirect_to new_investigation_accident_or_incident_path(@investigation, event_type: event_type)
    end

  private

    def accident_or_incident_type_form
      @accident_or_incident_type_form ||= AccidentOrIncidentTypeForm.new(event_type: event_type)
    end

    def investigation
      @investigation ||= Investigation
                        .find_by!(pretty_id: params[:investigation_pretty_id])
                        .decorate
    end

    def event_type
      return unless params[:investigation] && params[:investigation][:event_type]
      params[:investigation][:event_type]
    end
  end
end
