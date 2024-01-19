module Investigations
  class AccidentOrIncidentsController < Investigations::BaseController
    before_action :set_investigation
    before_action :authorize_investigation_updates, only: %i[new create edit update]
    before_action :set_investigation_breadcrumbs

    def new
      @accident_or_incident_form = AccidentOrIncidentForm.new({ type: params["type"] })
    end

    def create
      @accident_or_incident_form = AccidentOrIncidentForm.new(accident_or_incident_params)
      return render(:new) if @accident_or_incident_form.invalid?

      AddAccidentOrIncidentToNotification.call!(
        @accident_or_incident_form.attributes.merge({
          notification: @investigation,
          user: current_user,
        })
      )

      ahoy.track "Added accident or incident", { notification_id: @investigation.id }
      redirect_to investigation_supporting_information_index_path(@investigation), flash: { success: "The supporting information was updated" }
    end

    def show
      authorize @investigation, :view_non_protected_details?
      @accident_or_incident = @investigation.unexpected_events.find(params[:id]).decorate
    end

    def edit
      @accident_or_incident = @investigation.unexpected_events.find(params[:id])
      @accident_or_incident_form = AccidentOrIncidentForm.from(@accident_or_incident)

      @type = @accident_or_incident.type
      @accident_or_incident = @accident_or_incident.decorate
    end

    def update
      @accident_or_incident = @investigation.unexpected_events.find(params[:id])
      @accident_or_incident_form = AccidentOrIncidentForm.from(@accident_or_incident)
      @accident_or_incident_form.assign_attributes(accident_or_incident_params)

      if @accident_or_incident_form.valid?
        UpdateAccidentOrIncident.call!(
          @accident_or_incident_form.serializable_hash.merge({
            accident_or_incident: @accident_or_incident,
            notification: @investigation,
            user: current_user
          })
        )
        ahoy.track "Updated accident or incident", { notification_id: @investigation.id }
        redirect_to investigation_supporting_information_index_path(@investigation), flash: { success: "The supporting information was updated" }
      else
        @type = type
        render :edit
      end
    end

  private

    def type
      params[:accident_or_incident_form][:type]
    end

    def accident_or_incident_params
      params.require(:accident_or_incident_form).permit(:is_date_known, :severity, :severity_other, :additional_info, :usage, :investigation_product_id, :type, date: %i[day month year])
    end
  end
end
