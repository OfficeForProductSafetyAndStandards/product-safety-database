module Investigations
  class CoronavirusRelatedController < ApplicationController
    def show
      @investigation = Investigation.find_by!(pretty_id: params.require(:investigation_pretty_id)).decorate
    end

    def update
      investigation = Investigation.find_by(pretty_id: params.require(:investigation_pretty_id))

      investigation.assign_attributes(params.require(:investigation).permit(:coronavirus_related))
      create_audit = investigation.coronavirus_related_changed?

      investigation.save!

      AuditActivity::Investigation::UpdateCoronavirusStatus.from(investigation) if create_audit

      redirect_to investigation_path(investigation), success: "#{investigation.case_type.titleize} was successfully updated."
    end
  end
end
