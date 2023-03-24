module Investigations
  class AccidentOrIncidentsController < ApplicationController
    def new
      authorize investigation, :update?
      @accident_or_incident_form = AccidentOrIncidentForm.new({ type: params["type"] })
    end

    def create
      authorize investigation, :update?
      @accident_or_incident_form = AccidentOrIncidentForm.new(accident_or_incident_params)
      return render(:new) if @accident_or_incident_form.invalid?

      AddAccidentOrIncidentToCase.call!(
        @accident_or_incident_form.attributes.merge({
          investigation:,
          user: current_user,
        })
      )

      redirect_to investigation_supporting_information_index_path(investigation), flash: { success: "The supporting information has been updated." }
    end

    def show
      authorize investigation, :view_non_protected_details?
      @accident_or_incident = investigation.unexpected_events.find(params[:id]).decorate
    end

    def edit
      authorize investigation, :update?

      @accident_or_incident = investigation.unexpected_events.find(params[:id])

      @accident_or_incident_form = AccidentOrIncidentForm.from(@accident_or_incident)

      @type = @accident_or_incident.type
      @accident_or_incident = @accident_or_incident.decorate
    end

    def update
      authorize investigation, :update?

      @accident_or_incident = investigation.unexpected_events.find(params[:id])
      @accident_or_incident_form = AccidentOrIncidentForm.from(@accident_or_incident)
      @accident_or_incident_form.assign_attributes(accident_or_incident_params)

      if @accident_or_incident_form.valid?
        UpdateAccidentOrIncident.call!(
          @accident_or_incident_form.serializable_hash.merge({
            accident_or_incident: @accident_or_incident,
            investigation:,
            user: current_user
          })
        )

        redirect_to investigation_supporting_information_index_path(investigation), flash: { success: "The supporting information has been updated." }

      else
        @type = type
        render :edit
      end
    end

  private

    def investigation
      @investigation ||= Investigation
                        .find_by!(pretty_id: params[:investigation_pretty_id])
                        .decorate
    end

    def type
      params[:accident_or_incident_form][:type]
    end

    def accident_or_incident_params
      params.require(:accident_or_incident_form).permit(:is_date_known, :severity, :severity_other, :additional_info, :usage, :investigation_product_id, :type, date: %i[day month year])
    end
  end
end
