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

      result = ChangeCaseCoronavirusStatus.call!(investigation: @investigation, status: @coronavirus_related_form.coronavirus_related, user: current_user)

      if result.changes_made
        flash[:success] = I18n.t(".success", scope: "investigations.coronavirus_related", case_type: @investigation.case_type)
      end

      redirect_to investigation_path(@investigation)
    end
  end
end
