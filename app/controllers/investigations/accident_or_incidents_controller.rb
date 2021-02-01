module Investigations
  class AccidentOrIncidentsController < ApplicationController
    def new
      @investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id]).decorate
      authorize investigation, :update?
      @accident_or_incident_form = AccidentOrIncidentForm.new
      @event_type = params[:event_type]
    end

    def create
      authorize investigation, :update?
      @accident_or_incident_form = AccidentOrIncidentForm.new(params.require(:accident_or_incident).permit(:is_date_known, :severity, :severity_other, :additional_info, :usage, :product, :event_type, date: %i[day month year]))
      return render(:new) if accident_or_incident_form.invalid?

      result = AddAccidentOrIncidentToCase.call!(
        @accident_or_incident_form.attributes.merge({
          investigation: investigation,
          user: current_user,
        })
      )


      redirect_to investigation_supporting_information_index_path(investigation)
    end

    # private
    #
    def accident_or_incident_form
      @accident_or_incident_form ||= AccidentOrIncidentForm.new
    end

    def investigation
      @investigation ||= Investigation
                        .find_by!(pretty_id: params[:investigation_pretty_id])
                        .decorate
    end
  end
end
