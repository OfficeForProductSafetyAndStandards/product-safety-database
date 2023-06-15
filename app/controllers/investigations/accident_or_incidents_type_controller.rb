module Investigations
  class AccidentOrIncidentsTypeController < ApplicationController
    before_action :set_investigation
    before_action :authorize_investigation_updates
    before_action :set_case_breadcrumbs

    def new
      @accident_or_incident_type_form = AccidentOrIncidentTypeForm.new(type: params[:type])
      return render "no_products" if @investigation.products.empty?
    end

    def create
      @accident_or_incident_type_form = AccidentOrIncidentTypeForm.new(type:)
      return render(:new) if @accident_or_incident_type_form.invalid?

      redirect_to new_investigation_accident_or_incident_path(@investigation, type:)
    end

  private

    def set_investigation
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id]).decorate
    end

    def authorize_investigation_updates
      authorize @investigation, :update?
    end

    def type
      return unless params[:investigation] && params[:investigation][:type]

      params[:investigation][:type]
    end
  end
end
