module Investigations
  class CoronavirusRelatedController < ApplicationController
    def show
      @investigation = Investigation.find_by!(pretty_id: params.require(:investigation_pretty_id)).decorate
    end

    def update
      @investigation = Investigation.find_by!(pretty_id: params.require(:investigation_pretty_id)).decorate
      @investigation.assign_attributes(params.require(:investigation).permit(:coronavirus_related))

      return render :show unless @investigation.valid? && @investigation.coronavirus_related_changed?

      @investigation.save
      AuditActivity::Investigation::UpdateCoronavirusStatus.from(@investigation)

      redirect_to investigation_path(@investigation), success: "#{@investigation.case_type.titleize} was successfully updated."
    end
  end
end
