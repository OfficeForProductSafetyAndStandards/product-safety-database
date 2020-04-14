module Investigations
  class CoronavirusRelatedController < ApplicationController
    def show
      @investigation = Investigation.find_by!(pretty_id: params.require(:investigation_pretty_id)).decorate
    end

    def update
      @investigation = Investigation.find_by!(pretty_id: params.require(:investigation_pretty_id)).decorate
      @investigation.assign_attributes(params.require(:investigation).permit(:coronavirus_related))

      return render :show unless @investigation.valid?

      if @investigation.coronavirus_related_changed?
        @investigation.save
        AuditActivity::Investigation::UpdateCoronavirusStatus.from(@investigation)
        flash[:success] = I18n.t(".success", scope: "investigations.coronavirus_related", case_title: @investigation.case_type.titleize)
      end

      redirect_to investigation_path(@investigation)
    end
  end
end
