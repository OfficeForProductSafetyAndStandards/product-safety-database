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
      @accident_or_incident_form = AccidentOrIncidentForm.new(params.require(:accident_or_incident).permit(:is_date_known, :severity, :severity_other, :additional_info, :usage, :product_id, :event_type, date: %i[day month year]))
      @event_type = params[:accident_or_incident][:event_type]
      return render(:new) if accident_or_incident_form.invalid?

      result = AddAccidentOrIncidentToCase.call!(
        @accident_or_incident_form.attributes.merge({
          investigation: investigation,
          user: current_user,
        })
      )

      redirect_to investigation_supporting_information_index_path(investigation, flash: { success: "#{@event_type.capitalize} was successfully added." })
    end

    def show
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id]).decorate
      authorize @investigation, :view_non_protected_details?
      @accident_or_incident = @investigation.accident_or_incidents.find(params[:id]).decorate
    end

    def edit
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])

      authorize @investigation, :update?

      @accident_or_incident = @investigation.accident_or_incidents.find(params[:id])

      @accident_or_incident_form = AccidentOrIncidentForm.new(
        @accident_or_incident.serializable_hash(
          only: %i[date is_date_known product_id severity severity_other usage additional_info event_type]
        )
      )

      @event_type = @accident_or_incident.event_type
      @accident_or_incident = @accident_or_incident.decorate
      @investigation = @investigation.decorate
    end

    def update
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])

      authorize @investigation, :update?

      @accident_or_incident = @investigation.accident_or_incidents.find(params[:id])
      @accident_or_incident_form = AccidentOrIncidentForm.new(params.require(:accident_or_incident_form).permit(:is_date_known, :severity, :severity_other, :additional_info, :usage, :product_id, :event_type, date: %i[day month year]))

      if @accident_or_incident_form.valid?
        result = UpdateAccidentOrIncident.call!(
          @accident_or_incident_form.serializable_hash.merge({
            accident_or_incident: @accident_or_incident,
            investigation: @investigation,
            user: current_user
          })
        )

        redirect_to investigation_accident_or_incident_path(@investigation, result.accident_or_incident)

      else
        @event_type = params[:accident_or_incident_form][:event_type]
        @investigation = @investigation.decorate
        render :edit
      end
    end

  private

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
