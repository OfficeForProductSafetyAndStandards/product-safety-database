module Investigations
  class AccidentOrIncidentsTypeController < ApplicationController
    def new
      authorize investigation, :update?
      accident_or_incident_type_form
    end

    def create
      authorize investigation, :update?
      return render(:new) if accident_or_incident_type_form.invalid?
      redirect_to new_investigation_accident_or_incident_path(@investigation, type: type)
    end

  private

    def accident_or_incident_type_form
      @accident_or_incident_type_form ||= AccidentOrIncidentTypeForm.new(type: type)
    end

    def investigation
      @investigation ||= Investigation
                        .find_by!(pretty_id: params[:investigation_pretty_id])
                        .decorate
    end

    def type
      return unless params[:investigation] && params[:investigation][:type]
      params[:investigation][:type]
    end
  end
end
