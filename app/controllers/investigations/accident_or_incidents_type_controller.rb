module Investigations
  class AccidentOrIncidentsTypeController < ApplicationController

  def new
    authorize investigation, :update?
    accident_or_incident_type_form
  end

  def create
    authorize investigation, :update?
    return render(:new) if accident_or_incident_type_form.invalid?
    redirect_to accident_or_incidents_path(type: accident_or_incident_type_form.type)
  end

  private

  def accident_or_incident_type_form
    @accident_or_incident_type_form ||= AccidentOrIncidentTypeForm.new(accident_or_incident_type_params)
  end

  def investigation
    @investigation ||= Investigation
                      .find_by!(pretty_id: params[:investigation_pretty_id])
                      .decorate
  end

  def accident_or_incident_type_params
    params.require(:investigation).permit(:type)
  end
end
