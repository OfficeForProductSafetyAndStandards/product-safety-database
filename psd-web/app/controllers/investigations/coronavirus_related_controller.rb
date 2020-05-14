module Investigations
  class CoronavirusRelatedController < ApplicationController
    def show
      @investigation = Investigation.find_by!(pretty_id: params.require(:investigation_pretty_id)).decorate
      authorize @investigation, :update?
      @coronavirus_related_form = CoronavirusRelatedForm.new(coronavirus_related: @investigation.coronavirus_related)
    end

    def update
      @investigation = Investigation.find_by!(pretty_id: params.require(:investigation_pretty_id)).decorate
      authorize @investigation, :update?
      @coronavirus_related_form = CoronavirusRelatedForm.new(params.require(:investigation).permit(:coronavirus_related))
      return render :show unless @coronavirus_related_form.valid?

      @investigation.coronavirus_related = @coronavirus_related_form.coronavirus_related

      if @investigation.coronavirus_related_changed?
        @investigation.save!
        AuditActivity::Investigation::UpdateCoronavirusStatus.from(@investigation)
        flash[:success] = I18n.t(".success", scope: "investigations.coronavirus_related", case_title: @investigation.case_type.upcase_first)
      end

      redirect_to investigation_path(@investigation)
    end
  end
end
